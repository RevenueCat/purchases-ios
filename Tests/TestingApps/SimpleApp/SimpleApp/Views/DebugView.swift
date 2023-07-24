//
//  ContentView.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import SwiftUI
import RevenueCat

struct DebugView: View {

    @State
    private var debug = false

    var body: some View {
        Button {
            self.debug = true
        } label: {
            Text(verbatim: "Debug")
        }
        .debugRevenueCatOverlay(isPresented: self.$debug)
    }

}
