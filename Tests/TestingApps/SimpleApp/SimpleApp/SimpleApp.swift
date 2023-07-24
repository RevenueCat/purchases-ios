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

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppContentView()
            }
            .presentPaywallIfNecessary { !$0.hasPro }
            .overlay {
                DebugView()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

}

extension CustomerInfo {

    var hasPro: Bool {
        return self.entitlements.active.contains { $1.identifier == Configuration.entitlement }
    }

}
