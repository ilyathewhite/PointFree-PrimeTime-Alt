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

struct CountAndFavoritePrimes: Equatable {
    let count: Int
    let favoritePrimes: [Int]
}

extension Notification.Name {
    static let addedFavoritePrime = Notification.Name("addedFavoritePrime")
    static let removedFavoritePrime = Notification.Name("removedFavoritePrime")
}

extension Counter.State {
    var shared: CountAndFavoritePrimes {
        CountAndFavoritePrimes(count: count, favoritePrimes: favoritePrimes)
    }
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
            state.count = shared.count
            state.favoritePrimes = shared.favoritePrimes
            return []

        case .updateActivity(let activity):
            state.activityFeed.append(activity)
            return [{ _ in
                print(activity)
            }]
        }
    }
}

struct RootView: View {
    @ObservedObject var store: Store<Root.State, Root.Action>

    init() {
        let store = Store<Root.State, Root.Action>(
            Root.State(),
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
                reducer: Counter.reducer(state:action:)
            )

            store.subscribe(to: counterStore, \.shared, with: { .update($0) })

            return CounterView(store: counterStore)
        }()

        let favoritePrimesView = { () -> FavoritePrimesView in
            let favoritePrimesStore = Store<[Int], FavoritePrimes.Action>(
                store.state.favoritePrimes,
                reducer: FavoritePrimes.reducer(state:action:)
            )

            store.subscribe(to: favoritePrimesStore, \.self, with: { [unowned store] in
                .update(CountAndFavoritePrimes(count: store.state.count, favoritePrimes: $0))
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
