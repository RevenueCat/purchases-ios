//
//  ContentView.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import SwiftUI
import RevenueCat

struct ContentView: View {

    #if os(macOS) || os(xrOS)
    @State
    private var debug = false
    #endif

    var body: some View {
        ZStack {
            Content()

            #if os(macOS) || os(xrOS)
            Button {
                self.debug = true
            } label: {
                Text("Debug")
            }
            #endif
        }
        #if os(macOS) || os(xrOS)
        .debugRevenueCatOverlay(isPresented: self.$debug)
        #else
        .debugRevenueCatOverlay()
        #endif
    }

}
