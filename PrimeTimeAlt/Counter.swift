//
//  CounterView.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 10/31/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import SwiftUI
import Combine

enum Counter {
    enum Action {
        case decrTapped
        case incrTapped
        case nthPrimeButtonTapped
        case nthPrimeResponse(Int?)
        case nthPrimeAlertDismissButtonTapped
        case update(CountAndFavoritePrimes)
    }

    struct State {
        typealias ButtonInfo = (title: String, action: Action)

        let navigationBarTitle = "Counter demo"
        let minusButtonInfo: ButtonInfo = ("+", .incrTapped)
        let plusButtonInfo: ButtonInfo = ("-", .decrTapped)
        let isPrimeButtonTitle = "Is this prime?"

        var nthPrimeButtonInfo: ButtonInfo
        var countDescription: String
        var count: Int
        var favoritePrimes: [Int]
        var countPrime: Int?
        var isNthPrimeButtonDisabled = false
        var isPrimeAlertLabel: String
        var istNthPrimeAlertShown = false

        var shared: CountAndFavoritePrimes {
            get { CountAndFavoritePrimes(count: count, favoritePrimes: favoritePrimes) }
            set { count = newValue.count; favoritePrimes = newValue.favoritePrimes }
        }

        init(count: Int, favoritePrimes: [Int]) {
            self.count = count
            self.favoritePrimes = favoritePrimes
            countDescription = Counter.countDescription(count)
            nthPrimeButtonInfo = Counter.nthButtonInfo(count)
            isPrimeAlertLabel = Counter.isPrimerAlertLabel(count: count, countPrime: countPrime)
        }
    }

    static func reducer(state: inout State, action: Action) -> [Effect<Action>] {
        defer {
            state.countDescription = Counter.countDescription(state.count)
            state.nthPrimeButtonInfo = Counter.nthButtonInfo(state.count)
            state.isPrimeAlertLabel = Counter.isPrimerAlertLabel(count: state.count, countPrime: state.countPrime)
        }

        switch action {
        case .decrTapped:
            state.count -= 1
            return []

        case .incrTapped:
            state.count += 1
            return []

        case .nthPrimeButtonTapped:
            state.isNthPrimeButtonDisabled = true
            let count = state.count
            return [{ callback in
                nthPrime(count) { prime in
                    DispatchQueue.main.async {
                        callback(.nthPrimeResponse(prime))
                    }
                }
            }]

        case let .nthPrimeResponse(prime):
            state.countPrime = prime
            state.isNthPrimeButtonDisabled = false
            state.istNthPrimeAlertShown = true
            return []

        case .nthPrimeAlertDismissButtonTapped:
            state.istNthPrimeAlertShown = false
            return []

        case .update(let shared):
            if state.shared != shared {
                state.shared = shared
            }
            return []
        }
    }

    static func reducerWillMutate(state: State, action: Action) -> Bool {
        switch action {
        case .decrTapped,
             .incrTapped,
             .nthPrimeButtonTapped,
             .nthPrimeResponse,
             .nthPrimeAlertDismissButtonTapped:
            return true

        case .update(let shared):
            return state.shared != shared
        }
    }


    static func countDescription(_ count: Int) -> String {
        return String(count)
    }

    static func nthButtonInfo(_ count: Int) -> State.ButtonInfo {
        State.ButtonInfo(
            title: "What is the \(ordinal(count)) prime?",
            action: .nthPrimeButtonTapped
        )
    }

    static func isPrimerAlertLabel(count: Int, countPrime :Int?) -> String {
        guard let countPrime = countPrime else { return "" }
        return "The \(ordinal(count)) prime is \(countPrime)"
    }

    static func ordinal(_ n: Int) -> String {
      let formatter = NumberFormatter()
      formatter.numberStyle = .ordinal
      return formatter.string(for: n) ?? ""
    }
}

public struct CounterView: View {
    @ObservedObject var store: Store<Counter.State, Counter.Action>
    @State private var isPrimeModalShown = false

    init(store: Store<Counter.State, Counter.Action>) {
        self.store = store
    }

    func button(_ info: Counter.State.ButtonInfo) -> some View {
        Button(info.title) { self.store.send(info.action) }
    }

    public var body: some View {
        let state = self.store.state
        let store = self.store
        return VStack {
            HStack {
                button(state.minusButtonInfo)
                Text(state.countDescription)
                button(state.plusButtonInfo)
            }

            Button(state.isPrimeButtonTitle) { self.isPrimeModalShown = true }
            button(state.nthPrimeButtonInfo).disabled(state.isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationBarTitle(state.navigationBarTitle)
        .sheet(
            isPresented: $isPrimeModalShown,
            content: { () -> IsPrimeModalView in
                let isPrimeModalStore = Store<IsPrimeModal.State, IsPrimeModal.Action>(
                    IsPrimeModal.State(count: state.count, favoritePrimes: state.favoritePrimes),
                    reducerWillMutate: IsPrimeModal.reducerWillMutate(state:action:),
                    reducer: IsPrimeModal.reducer(state:action:)
                )

                store.add(subscription: isPrimeModalStore.$state.map(\.shared).sink { [weak store] in
                    store?.send(.update($0))
                })

                return IsPrimeModalView(store: isPrimeModalStore)
            }
        )
        .alert(isPresented: .constant(state.istNthPrimeAlertShown)) {
            Alert(
                title: Text(state.isPrimeAlertLabel),
                dismissButton: .default(Text("Ok")) {
                    self.store.send(.nthPrimeAlertDismissButtonTapped)
                }
            )
        }
    }
}

struct CounterView_Previews: PreviewProvider {
    static let store = Store<Counter.State, Counter.Action>(
        Counter.State(count: 11, favoritePrimes: []),
        reducerWillMutate: Counter.reducerWillMutate(state:action:),
        reducer: Counter.reducer(state:action:)
    )

    static var previews: some View {
        CounterView(store: store)
    }
}
