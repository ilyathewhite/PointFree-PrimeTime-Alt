//
//  Store.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 10/31/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import Foundation
import Combine

public typealias Effect<Action> = (@escaping (Action) -> Void) -> Void

public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

public class Store<State, Action>: ObservableObject {
    private let reducer: Reducer<State, Action>
    private var subscriptions = Set<AnyCancellable>()

    @Published public private(set) var state: State

    public init(_ initialValue: State, reducer: @escaping Reducer<State, Action>) {
        self.reducer = reducer
        self.state = initialValue
    }

    public func send(_ action: Action) {
        let effects = self.reducer(&(self.state), action)
        effects.forEach { effect in
            effect(self.send)
        }
    }

    public func subscribe<OtherState, OtherValue, OtherAction>(
        to otherStore: Store<OtherState, OtherAction>,
        _ keyPath: KeyPath<OtherState, OtherValue>,
        with action: @escaping (OtherValue) -> Action,
        compare: @escaping (OtherValue, OtherValue) -> Bool
    ) {
        // dropFirst() to send only future values because the already has the current
        // value, and sending it again causes an infinite update cycle
        subscriptions.insert(otherStore.$state.map(keyPath).removeDuplicates(by: compare).dropFirst().sink { [weak self] in
            self?.send(action($0))
        })
    }

    public func subscribe<OtherState, OtherValue: Equatable, OtherAction>(
        to otherStore: Store<OtherState, OtherAction>,
        _ keyPath: KeyPath<OtherState, OtherValue>,
        with action: @escaping (OtherValue) -> Action) {
        subscribe(to: otherStore, keyPath, with: action, compare: ==)
    }
}

