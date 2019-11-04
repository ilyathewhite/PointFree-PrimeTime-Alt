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
public typealias ReducerWillMutate<Value, Action> = (Value, Action) -> Bool

public class Store<State, Action>: ObservableObject {
    private let reducer: Reducer<State, Action>
    private let reducerWillMutate: ReducerWillMutate<State, Action>
    private var subscriptions = Set<AnyCancellable>()

    @Published public private(set) var state: State

    public init(_ initialValue: State, reducerWillMutate: @escaping ReducerWillMutate<State, Action>, reducer: @escaping Reducer<State, Action>) {
        self.reducer = reducer
        self.reducerWillMutate = reducerWillMutate
        self.state = initialValue
    }

    public func send(_ action: Action) {
        guard self.reducerWillMutate(state, action) else { return }
        let effects = self.reducer(&(self.state), action)
        effects.forEach { effect in
            effect(self.send)
        }
    }

    public func add(subscription: AnyCancellable) {
        subscriptions.insert(subscription)
    }
}

