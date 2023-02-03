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
    private var revenueCatCustomerData: RevenueCatCustomerData

    @StateObject
    private var observerModeManager: ObserverModeManager

    init(configuration: ConfiguredPurchases) {
        self.configuration = configuration
        self._revenueCatCustomerData = .init(wrappedValue: .init())
        self._observerModeManager = .init(
            wrappedValue: .init(observerModeEnabled: !configuration.purchases.finishTransactions)
        )
    }

    var body: some View {
        HomeView()
            .environmentObject(self.revenueCatCustomerData)
            .environmentObject(self.observerModeManager)
            .task {
                for await customerInfo in self.configuration.purchases.customerInfoStream {
                    self.revenueCatCustomerData.customerInfo = customerInfo
                    self.revenueCatCustomerData.appUserID = self.configuration.purchases.appUserID
                }
            }
    }

}

final class RevenueCatCustomerData: ObservableObject {

    @Published var appUserID: String? = nil
    @Published var customerInfo: CustomerInfo? = nil

}
