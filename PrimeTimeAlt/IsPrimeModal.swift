//
//  IsPrimeModalView.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 10/29/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import SwiftUI

enum IsPrimeModal {
    enum Action {
        case saveFavoritePrimeTapped
        case removeFavoritePrimeTapped
        case update(CountAndFavoritePrimes)
    }

    struct State {
        var count: Int
        var favoritePrimes: [Int]
        var countDescription: String
        var buttonInfo: (actionTitle: String, action: Action)?

        init(count: Int, favoritePrimes: [Int]) {
            self.count = count
            self.favoritePrimes = favoritePrimes
            countDescription = IsPrimeModal.countDescription(count)
            buttonInfo = nil
            buttonInfo = IsPrimeModal.buttonInfo(state: self)
        }

        var shared: CountAndFavoritePrimes {
            get { CountAndFavoritePrimes(count: count, favoritePrimes: favoritePrimes) }
            set { count = newValue.count; favoritePrimes = newValue.favoritePrimes }
        }
    }

    static func reducer(state: inout State, action: Action) -> [Effect<Action>] {
        defer {
            state.countDescription = countDescription(state.count)
            state.buttonInfo = buttonInfo(state: state)
        }

        switch action {
        case .saveFavoritePrimeTapped:
            let count = state
            state.favoritePrimes.append(state.count)
            return [{ _ in
                let note = Notification(name: .addedFavoritePrime, userInfo: ["value": count])
                NotificationCenter.default.post(note)
            }]

        case .removeFavoritePrimeTapped:
            let count = state.count
            state.favoritePrimes.removeAll(where: { $0 == state.count })
            return [{ _ in
                let note = Notification(name: .removedFavoritePrime, userInfo: ["value": count])
                NotificationCenter.default.post(note)
            }]

        case .update(let shared):
            if state.shared != shared {
                state.shared = shared
            }
            return []
        }
    }

    static func reducerWillMutate(state: State, action: Action) -> Bool {
        switch action {
        case .saveFavoritePrimeTapped,
             .removeFavoritePrimeTapped:
            return true

        case .update(let shared):
            return state.shared != shared
        }
    }

    private static func countDescription(_ count: Int) -> String {
        let suffix = isPrime(count) ? " is prime 🎉" : " is not prime :("
        return "\(count)\(suffix)"
    }

    private static func buttonInfo(state: State) -> (actionTitle: String, action: Action)? {
        if isPrime(state.count) {
            if state.favoritePrimes.contains(state.count) {
                return (
                    actionTitle: "Remove from favorite primes",
                    action: .removeFavoritePrimeTapped
                )
            }
            else {
                return (
                    actionTitle: "Save to favorite primes",
                    action: .saveFavoritePrimeTapped
                )
            }
        }
        else {
            return nil
        }
    }

    static func isPrime(_ p: Int) -> Bool {
        if p <= 1 { return false }
        if p <= 3 { return true }
        for i in 2...Int(sqrtf(Float(p))) {
            if p % i == 0 { return false }
        }
        return true
    }
}

struct IsPrimeModalView: View {
    @ObservedObject var store: Store<IsPrimeModal.State, IsPrimeModal.Action>

    var body: some View {
        VStack {
            Text(store.state.countDescription)
            store.state.buttonInfo.map { (text, action) in
                Button(text, action: { self.store.send(action) })
            }
        }
    }
}

struct IsPrimeModalView_Previews: PreviewProvider {
    static let store = Store<IsPrimeModal.State, IsPrimeModal.Action>(
        IsPrimeModal.State(count: 11, favoritePrimes: []),
        reducerWillMutate: IsPrimeModal.reducerWillMutate(state:action:),
        reducer: IsPrimeModal.reducer(state:action:)
    )

    static var previews: some View {
        IsPrimeModalView(store: Self.store)
    }
}
