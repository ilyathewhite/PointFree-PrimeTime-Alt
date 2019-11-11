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
    typealias Store = StateStore<State, MutatingAction, Never>
    typealias Reducer = Store.Reducer

    enum MutatingAction {
        case update(CountAndFavoritePrimes)
        case updateActivity(State.Activity)
    }

    struct State {
        var count = 0
        var favoritePrimes: [Int] = []
        var activityFeed: [Activity] = []

        enum ActivityType {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
        }

        struct Activity {
            let timestamp: Date
            let type: ActivityType

            static func activity(_ value: ActivityType) -> State.Activity {
                State.Activity(timestamp: Date(), type: value)
            }
        }
    }

    static let reducer = Reducer { state, action in
        switch action {
        case .update(let shared):
            state.count = shared.count
            state.favoritePrimes = shared.favoritePrimes
            return nil

        case .updateActivity(let activity):
            state.activityFeed.append(activity)
            return Reducer.effect {
                print(activity)
                return .noAction
            }
        }
    }
}

struct RootView: View {
    @ObservedObject var store: Root.Store

    init() {
        let store = Root.Store(Root.State(), reducer: Root.reducer)
        self.store = store
        NotificationCenter.default.addObserver(forName: .addedFavoritePrime, object: nil, queue: .main) { notification in
            guard let count = notification.userInfo?["value"] as? Int else { return }
            store.send(.mutating(.updateActivity(.activity(.addedFavoritePrime(count)))))
        }
        NotificationCenter.default.addObserver(forName: .removedFavoritePrime, object: nil, queue: .main) { notification in
            guard let count = notification.userInfo?["value"] as? Int else { return }
            store.send(.mutating(.updateActivity(.activity(.removedFavoritePrime(count)))))
        }
    }

    var body: some View {
        let counterView = { () -> CounterView in
            let counterStore = Counter.Store(
                Counter.State(count: store.state.count, favoritePrimes: store.state.favoritePrimes),
                reducer: Counter.reducer
            )

            store.subscribe(to: counterStore, \.shared, with: { .mutating(.update($0)) })

            return CounterView(store: counterStore)
        }()

        let favoritePrimesView = { () -> FavoritePrimesView in
            let favoritePrimesStore = FavoritePrimes.Store(
                store.state.favoritePrimes,
                reducer: FavoritePrimes.reducer
            )

            store.subscribe(to: favoritePrimesStore, \.self, with: { [unowned store] in
                .mutating(.update(CountAndFavoritePrimes(count: store.state.count, favoritePrimes: $0)))
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
