//
//  Root.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 11/2/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

extension Notification.Name {
    static let addedFavoritePrime = Notification.Name("addedFavoritePrime")
    static let removedFavoritePrime = Notification.Name("removedFavoritePrime")
}

enum Root {
    enum Action {
        case update(CountAndFavoritePrimes)
        case updateActivity(State.Activity)
    }

    struct State {
        var count = 0
        var favoritePrimes: [Int] = []
        var activityFeed: [Activity] = []

        var shared: CountAndFavoritePrimes {
            get { CountAndFavoritePrimes(count: count, favoritePrimes: favoritePrimes) }
            set { count = newValue.count; favoritePrimes = newValue.favoritePrimes }
        }

        struct Activity {
            let timestamp: Date
            let type: ActivityType

            enum ActivityType {
                case addedFavoritePrime(Int)
                case removedFavoritePrime(Int)
            }
        }
    }

    static func reducer(state: inout State, action: Action) -> [Effect<Action>] {
        switch action {
        case .update(let shared):
            state.shared = shared
            return []

        case .updateActivity(let activity):
            state.activityFeed.append(activity)
            return [{ _ in
                print(activity)
            }]
        }
    }

    static func reducerWillMutate(state: State, action: Action) -> Bool {
        switch action {
        case .update(let shared):
            return state.shared != shared

        case .updateActivity:
            return true
        }
    }
}

struct RootView: View {
    @ObservedObject var store: Store<Root.State, Root.Action>

    init() {
        let store = Store<Root.State, Root.Action>(
            Root.State(),
            reducerWillMutate: Root.reducerWillMutate(state:action:),
            reducer: Root.reducer(state:action:)
        )
        self.store = store
        NotificationCenter.default.addObserver(forName: .addedFavoritePrime, object: nil, queue: .main) { notification in
            guard let count = notification.userInfo?["value"] as? Int else { return }
            store.send(.updateActivity(Root.State.Activity(timestamp: Date(), type: .addedFavoritePrime(count))))
        }
        NotificationCenter.default.addObserver(forName: .removedFavoritePrime, object: nil, queue: .main) { notification in
            guard let count = notification.userInfo?["value"] as? Int else { return }
            store.send(.updateActivity(Root.State.Activity(timestamp: Date(), type: .removedFavoritePrime(count))))
        }
    }

    var body: some View {
        let counterView = { () -> CounterView in
            let counterStore = Store<Counter.State, Counter.Action>(
                Counter.State(count: store.state.count, favoritePrimes: store.state.favoritePrimes),
                reducerWillMutate: Counter.reducerWillMutate(state:action:),
                reducer: Counter.reducer(state:action:)
            )

            store.add(subscription: counterStore.$state.map(\.shared).sink { [weak store] in
                store?.send(.update($0))
            })

            return CounterView(store: counterStore)
        }()

        let favoritePrimesView = { () -> FavoritePrimesView in
            let favoritePrimesStore = Store<[Int], FavoritePrimes.Action>(
                store.state.favoritePrimes,
                reducerWillMutate: FavoritePrimes.reducerWillMutate(state:action:),
                reducer: FavoritePrimes.reducer(state:action:)
            )

            store.add(subscription: favoritePrimesStore.$state.sink { [weak store] in
                guard let store = store else { return }
                let shared = CountAndFavoritePrimes(count: store.state.count, favoritePrimes: $0)
                store.send(.update(shared))
            })

            return FavoritePrimesView(store: favoritePrimesStore)
        }()

        return NavigationView {
            List {
                NavigationLink( "Counter demo", destination: counterView)
                NavigationLink("Favorite primes", destination: favoritePrimesView)
            }
            .navigationBarTitle("State management")
        }
    }
}
