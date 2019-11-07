//
//  IsPrimeModalView.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 10/29/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import SwiftUI

enum IsPrimeModal {
    typealias Store = StateStore<State, MutatingAction, Never>
    typealias Reducer = Store.Reducer

    enum MutatingAction {
        case saveFavoritePrimeTapped
        case removeFavoritePrimeTapped
    }

    struct State {
        var count: Int
        var favoritePrimes: [Int]
        var countDescription: String
        var buttonInfo: (actionTitle: String, action: MutatingAction)?

        init(count: Int, favoritePrimes: [Int]) {
            self.count = count
            self.favoritePrimes = favoritePrimes
            countDescription = IsPrimeModal.countDescription(count)
            buttonInfo = IsPrimeModal.buttonInfo(state: self)
        }
    }

    static let reducer = Reducer { state, action in
        defer {
            state.countDescription = countDescription(state.count)
            state.buttonInfo = buttonInfo(state: state)
        }

        switch action {
        case .saveFavoritePrimeTapped:
            let count = state.count
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
        }
    }

    private static func countDescription(_ count: Int) -> String {
        let suffix = isPrime(count) ? " is prime 🎉" : " is not prime :("
        return "\(count)\(suffix)"
    }

    private static func buttonInfo(state: State) -> (actionTitle: String, action: MutatingAction)? {
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
    @ObservedObject var store: IsPrimeModal.Store

    var body: some View {
        VStack {
            Text(store.state.countDescription)
            store.state.buttonInfo.map { (text, action) in
                Button(text, action: { self.store.send(.mutating(action)) })
            }
        }
    }
}

struct IsPrimeModalView_Previews: PreviewProvider {
    static let store = IsPrimeModal.Store(
        IsPrimeModal.State(count: 11, favoritePrimes: []),
        reducer: IsPrimeModal.reducer
    )

    static var previews: some View {
        IsPrimeModalView(store: Self.store)
    }
}
