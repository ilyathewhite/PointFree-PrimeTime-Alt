//
//  ContentView.swift
//  PrimeTimeAlt
//
//  Created by Ilya Belenkiy on 10/29/19.
//  Copyright © 2019 Ilya Belenkiy. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        IsPrimeModalView(model: IsPrimeModalView_Previews.model)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
