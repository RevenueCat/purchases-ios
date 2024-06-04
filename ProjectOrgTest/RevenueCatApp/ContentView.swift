//
//  ContentView.swift
//  RevenueCatApp
//
//  Created by James Borthwick on 2024-06-04.
//

import SwiftUI

import RevenueCat
import RevenueCatUI

struct ContentView: View {
    @State private var showingPaywall = false

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .onAppear {
                    Purchases.configure(withAPIKey: "haha!")
                }
            Button(action: {
                showingPaywall = true
            }, label: {
                Text("Show Paywall")
            })
        }
        .padding()
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    ContentView()
}
