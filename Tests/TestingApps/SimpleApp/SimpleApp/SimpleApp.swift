//
//  SimpleApp.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@main
struct SimpleApp: App {

    init() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = Configuration.proxyURL.isEmpty
            ? nil
            : URL(string: Configuration.proxyURL)!

        Purchases.configure(
            with: .init(withAPIKey: Configuration.apiKey)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    @State
    private var customerInfo: CustomerInfo?

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppContentView(customerInfo: self.customerInfo)
            }
                .overlay {
                    if let info = self.customerInfo, !info.hasPro {
                        PaywallScreen()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    DebugView()
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .task {
                    for await info in Purchases.shared.customerInfoStream {
                        self.customerInfo = info
                    }
                }
        }
    }

}

extension CustomerInfo {

    var hasPro: Bool {
        return self.entitlements.active.contains { $1.identifier == Configuration.entitlement }
    }

}
