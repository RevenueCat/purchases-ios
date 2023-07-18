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
    private var offering: Result<Offering, NSError>?

    @State
    private var customerInfo: CustomerInfo?

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppContentView(customerInfo: self.customerInfo)
            }
                .overlay {
                    if let info = self.customerInfo, !info.hasPro {
                        self.paywallView
                            .animation(.default, value: self.offering)
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

    @ViewBuilder
    private var paywallView: some View {
        if let offering = self.offering {
            switch offering {
            case let .success(offering):
                if let paywall = offering.paywall {
                    PaywallScreen(offering: offering, paywall: paywall)
                } else {
                    Text(
                        "Didn't find a paywall associated to the current offering.\n" +
                        "Check the logs for any potential errors."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.gray)
                }

            case let .failure(error):
                Text("Error loading offerings: \(error.localizedDescription)")
            }
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .task {
                    do {
                        self.offering = .success(try await Purchases.shared.offerings().current!)
                    } catch {
                        self.offering = .failure(error as NSError)
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
