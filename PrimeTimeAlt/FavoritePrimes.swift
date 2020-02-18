//
//  FavoritePrimes.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 11/2/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import ReducerArchitecture

enum FavoritePrimes {
    typealias Store = StateStore<[Int], MutatingAction, EffectAction>
    typealias Reducer = Store.Reducer

    enum MutatingAction {
        case deleteFavoritePrimes(IndexSet)
        case loadedFavoritePrimes([Int])
    }

    enum EffectAction {
        case saveButtonTapped
        case loadButtonTapped
    }

    static let reducer = Reducer(
        run: { state, action in
            switch action {
            case let .deleteFavoritePrimes(indexSet):
                for index in indexSet {
                    state.remove(at: index)
                }
                return nil

            case let .loadedFavoritePrimes(favoritePrimes):
                state = favoritePrimes
                return nil
            }
        },
        effect: { state, action in
            switch action {
            case .saveButtonTapped:
                return saveEffect(favoritePrimes: state)

            case .loadButtonTapped:
                return loadEffect()
            }
        }
    )

    private static func saveEffect(favoritePrimes: [Int]) -> Reducer.Effect {
        Reducer.effect {
            let data = try! JSONEncoder().encode(favoritePrimes)
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
                )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl
                .appendingPathComponent("favorite-primes.json")
            try! data.write(to: favoritePrimesUrl)
            return .noAction
        }
    }

    private static func loadEffect() -> Reducer.Effect {
        Reducer.effect {
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
                )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl
                .appendingPathComponent("favorite-primes.json")
            guard
                let data = try? Data(contentsOf: favoritePrimesUrl),
                let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data)
                else { return .noAction }
            return .mutating(.loadedFavoritePrimes(favoritePrimes))
        }
    }
}

public struct FavoritePrimesView: View {
    @ObservedObject var store: FavoritePrimes.Store

    init(store: FavoritePrimes.Store) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(self.store.state, id: \.self) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                self.store.send(.mutating(.deleteFavoritePrimes(indexSet)))
            }
        }
        .navigationBarTitle("Favorite primes")
        .navigationBarItems(
            trailing: HStack {
                Button("Save") {
                    self.store.send(.effect(.saveButtonTapped))
                }
                Button("Load") {
                    self.store.send(.effect(.loadButtonTapped))
                }
            }
        )
    }
}
