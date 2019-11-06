//
//  FavoritePrimes.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 11/2/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import Foundation
import SwiftUI

enum FavoritePrimes {
    enum Action {
        case deleteFavoritePrimes(IndexSet)
        case loadButtonTapped
        case loadedFavoritePrimes([Int])
        case saveButtonTapped
    }

    static func reducer(state: inout [Int], action: Action) -> [Effect<Action>] {
        switch action {
        case let .deleteFavoritePrimes(indexSet):
            for index in indexSet {
                state.remove(at: index)
            }
            return []

        case let .loadedFavoritePrimes(favoritePrimes):
            state = favoritePrimes
            return []

        case .saveButtonTapped:
            return [ saveEffect(favoritePrimes: state) ]

        case .loadButtonTapped:
            return [ loadEffect ]
        }
    }

    private static func saveEffect(favoritePrimes: [Int]) -> Effect<Action> {
        return { _ in
            let data = try! JSONEncoder().encode(favoritePrimes)
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
                )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl
                .appendingPathComponent("favorite-primes.json")
            try! data.write(to: favoritePrimesUrl)
            return
        }
    }

    private static let loadEffect: Effect<Action> = { callback in
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            )[0]
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        let favoritePrimesUrl = documentsUrl
            .appendingPathComponent("favorite-primes.json")
        guard
            let data = try? Data(contentsOf: favoritePrimesUrl),
            let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data)
            else { return }
        return callback(.loadedFavoritePrimes(favoritePrimes))
    }
}

public struct FavoritePrimesView: View {
    @ObservedObject var store: Store<[Int], FavoritePrimes.Action>

    init(store: Store<[Int], FavoritePrimes.Action>) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(self.store.state, id: \.self) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                self.store.send(.deleteFavoritePrimes(indexSet))
            }
        }
        .navigationBarTitle("Favorite primes")
        .navigationBarItems(
            trailing: HStack {
                Button("Save") {
                    self.store.send(.saveButtonTapped)
                }
                Button("Load") {
                  self.store.send(.loadButtonTapped)
                }
            }
        )
    }
}
