//
//  Store.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 10/31/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import Foundation
import Combine

public enum StateAction<MutatingAction, EffectAction> {
    case mutating(MutatingAction)
    case effect(EffectAction)
    case noAction
}

public typealias StateEffect<MutatingAction, EffectAction> =
    AnyPublisher<StateAction<MutatingAction, EffectAction>, Never>

public struct StateReducer<Value, MutatingAction, EffectAction> {
    public typealias Action = StateAction<MutatingAction, EffectAction>
    public typealias Effect = StateEffect<MutatingAction, EffectAction>

    let run: (inout Value, MutatingAction) -> Effect?
    let effect: (Value, EffectAction) -> Effect

    static func effect(_ body: @escaping () -> Action) -> Effect {
        Effect(
            Deferred {
                Future { promise in
                    promise(.success(body()))
                }
            }
        )
    }
}

extension StateReducer where EffectAction == Never {
    init(_ run: @escaping (inout Value, MutatingAction) -> Effect?) {
        self = StateReducer(run: run, effect: { _, effectAction in AnyPublisher(Just(.effect(effectAction))) })
    }
}

public class StateStore<State, MutatingAction, EffectAction>: ObservableObject {
    public typealias Reducer = StateReducer<State, MutatingAction, EffectAction>

    private let reducer: Reducer
    private var subscriptions = Set<AnyCancellable>()
    private var effects = PassthroughSubject<AnyPublisher<Reducer.Action, Never>, Never>()

    @Published public private(set) var state: State

    public init(_ initialValue: State, reducer: Reducer) {
        self.reducer = reducer
        self.state = initialValue

        subscriptions.insert(
            effects
                .flatMap { $0 }
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] in self?.send($0) })
        )
    }

    public func send(_ action: Reducer.Action) {
        let effect: Reducer.Effect?
        switch action {
        case .mutating(let mutatingAction):
            effect = reducer.run(&state, mutatingAction)
        case .effect(let effectAction):
            effect = reducer.effect(state, effectAction)
        case .noAction:
            effect = nil
        }

        if let e = effect {
            effects.send(e)
        }
    }

    public func subscribe<OtherState, OtherValue, OtherMutatingAction, OtherEffectAction>(
        to otherStore: StateStore<OtherState, OtherMutatingAction, OtherEffectAction>,
        _ keyPath: KeyPath<OtherState, OtherValue>,
        with action: @escaping (OtherValue) -> Reducer.Action,
        compare: @escaping (OtherValue, OtherValue) -> Bool
    ) {
        // dropFirst() to send only future values because the already has the current
        // value, and sending it again causes an infinite update cycle
        subscriptions.insert(otherStore.$state.map(keyPath).removeDuplicates(by: compare).dropFirst().sink { [weak self] in
            self?.send(action($0))
        })
    }

    public func subscribe<OtherState, OtherValue: Equatable, OtherMutatingAction, OtherEffectAction>(
        to otherStore: StateStore<OtherState, OtherMutatingAction, OtherEffectAction>,
        _ keyPath: KeyPath<OtherState, OtherValue>,
        with action: @escaping (OtherValue) -> Reducer.Action) {
        subscribe(to: otherStore, keyPath, with: action, compare: ==)
    }
}
