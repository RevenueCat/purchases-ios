//
//  ContentView.swift
//  Shared
//
//  Created by Josh Holtz on 1/10/22.
//

import SwiftUI

import Core
import RevenueCat

struct ContentView: View {

    let configuration: ConfiguredPurchases

    @StateObject
    private var observerModeManager: ObserverModeManager

    init(configuration: ConfiguredPurchases) {
        self.configuration = configuration
        self._observerModeManager = .init(
            wrappedValue: .init(observerModeEnabled: !configuration.purchases.finishTransactions)
        )
    }

    var body: some View {
        HomeView()
            .environmentObject(self.observerModeManager)
    }

}

final class RevenueCatCustomerData: ObservableObject {

    @Published var appUserID: String? = nil
    @Published var customerInfo: CustomerInfo? = nil
    @Published var metadata: [String: String]? = nil

}
