//
//  IsPrimeModalView.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 10/29/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import SwiftUI

class IsPrimeModelViewModel: ObservableObject {
    enum Action {
        case saveFavoritePrimeTapped
        case removeFavoritePrimeTapped
        case none
    }

    struct State {
        var count: Int
        var favoritePrimes: [Int]
        var countDescription: String
        var buttonInfo: (actionTitle: String, action: Action)?
    }

    @Published var state: State

    init(count: Int, favoritePrimes: [Int]) {
        state = State(count: count, favoritePrimes: favoritePrimes, countDescription: "", buttonInfo: nil)
        Self.reduce(state: &state, action: .none)
    }

    static func reduce(state: inout State, action: Action) -> Void {
        switch action {
        case .saveFavoritePrimeTapped:
            state.favoritePrimes.append(state.count)
        case .removeFavoritePrimeTapped:
            state.favoritePrimes.removeAll(where: { $0 == state.count })
        case .none:
            break
        }

        let suffix = isPrime(state.count) ? " is prime 🎉" : " is not prime :("
        state.countDescription = "\(state.count)\(suffix)"

        if isPrime(state.count) {
            if state.favoritePrimes.contains(state.count) {
                state.buttonInfo = (
                    actionTitle: "Remove from favorite primes",
                    action: .removeFavoritePrimeTapped
                )
            }
            else {
                state.buttonInfo = (
                    actionTitle: "Save to favorite primes",
                    action: .saveFavoritePrimeTapped
                )
            }
        }
        else {
            state.buttonInfo = nil
        }

    }
}

func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}

struct IsPrimeModalView: View {
    @ObservedObject var model: IsPrimeModelViewModel

    var body: some View {
        VStack {
            Text(model.state.countDescription)
            model.state.buttonInfo.map { (text, action) in
                Button(text, action: { IsPrimeModelViewModel.reduce(state: &self.model.state, action: action) })
            }
        }
    }
}

struct IsPrimeModalView_Previews: PreviewProvider {
    static let model = IsPrimeModelViewModel(
        count: 11,
        favoritePrimes: []
    )

    static var previews: some View {
        IsPrimeModalView(model: Self.model)
    }
}
