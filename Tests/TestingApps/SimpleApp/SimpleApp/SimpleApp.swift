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
                .with(usesStoreKit2IfAvailable: true)
        )
    }

    @State
    private var offering: Result<Offering, Error>?

    var body: some Scene {
        WindowGroup {
            Group {
                if let offering = self.offering {
                    switch offering {
                    case let .success(offering):
                        if let paywall = offering.paywall {
                            PaywallView(offering: offering, paywall: paywall)
                        } else {
                            Text(
                                "Didn't find a paywall associated to the current offering.\n" +
                                "Check the logs for any potential errors.")
                        }

                    case let .failure(error):
                        Text("Error loading offerings: \(error.localizedDescription)")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                DebugView()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .task {
                do {
                    self.offering = .success(try await Purchases.shared.offerings().current!)
                } catch {
                    self.offering = .failure(error)
                }
            }
        }
    }
}
