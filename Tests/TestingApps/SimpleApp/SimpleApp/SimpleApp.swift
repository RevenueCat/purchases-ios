//
//  SimpleApp.swift
//  SimpleApp
//
//  Created by Nacho Soto on 5/30/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

#warning("This needs to be configured.")
private let apiKey = ""
// Note: you can leave this empty to use the production server, or point to your own instance.
private let proxyURL = ""

@main
struct SimpleApp: App {
    init() {
        Purchases.logLevel = .verbose
        Purchases.proxyURL = proxyURL.isEmpty
            ? nil
            : URL(string: proxyURL)!

        Purchases.configure(
            with: .init(withAPIKey: apiKey)
        )
    }

    @State
    private var offering: Offering?

    var body: some Scene {
        WindowGroup {
            Group {
                if let offering = self.offering {
                    PaywallView(offering: offering)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                DebugView()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .task {
                self.offering = try? await Purchases.shared.offerings().current
            }
        }
    }
}
