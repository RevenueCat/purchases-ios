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
            with: .init(withAPIKey: Configuration.effectiveApiKey)
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                AppContentView()
            }
            #if DEBUG
            .overlay {
                if #available(iOS 16.0, macOS 13.0, *) {
                    DebugView()
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .offset(y: -50)
                }
            }
            #endif
        }
    }

}
