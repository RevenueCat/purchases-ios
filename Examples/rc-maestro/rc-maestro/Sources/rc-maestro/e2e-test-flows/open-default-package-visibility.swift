//
//  open-default-package-visibility.swift
//  Maestro
//
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
@_spi(Internal) import RevenueCat
import RevenueCatUI

extension E2ETestFlowView {
    /// Covers a paywall whose default-selected package is hidden by a conditional-visibility rule.
    ///
    /// The paywall swaps trial and non-trial package cards on a `can_trial` custom variable. The card
    /// marked "selected by default" is the trial one, so with `can_trial=false` it is hidden and the SDK
    /// has to fall back to a package that actually renders.
    ///
    /// Selection isn't assertable from the rendered radio buttons, so the flow taps the purchase button
    /// and reports which package the SDK was about to buy. `onPurchaseInitiated` declines to proceed, so
    /// no StoreKit sheet appears and nothing covers the label the flow asserts on.
    struct OpenDefaultPackageVisibility: View {

        static let offeringIdentifier = "[default pkg + visibility]"

        /// Absent unless the `can_trial` launch argument is passed, so the paywall renders whatever the
        /// dashboard default for the variable is.
        static var customVariableOverrides: [String: CustomVariableValue] {
            guard let raw = UserDefaults.standard.string(forKey: "can_trial") else {
                return [:]
            }
            return ["can_trial": .bool(raw == "true")]
        }

        enum GetOfferingsState {
            case loading
            case loaded(Offering)
            case failed(Error)
        }

        @State private var offeringsState: GetOfferingsState = .loading
        @State private var presentPaywall = false
        @State private var purchaseStartedPackage: String?

        var body: some View {
            VStack {
                Text("Default package visibility")
                    .font(.largeTitle)

                switch offeringsState {
                case .loading:
                    Text("Loading offerings...")
                case .loaded(let offering):
                    Button("Present Paywall") {
                        presentPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $presentPaywall) {
                        PaywallView(offering: offering)
                            .customPaywallVariables(Self.customVariableOverrides)
                            .onPurchaseInitiated { package, resume in
                                let identifier = package.identifier
                                Task { @MainActor in
                                    self.purchaseStartedPackage = identifier
                                    // Declining keeps the StoreKit sheet from covering the label below.
                                    resume(shouldProceed: false)
                                }
                            }
                    }
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }

                if let purchaseStartedPackage {
                    Text("selected package: \(purchaseStartedPackage)")
                }

                EntitlementView(identifier: "pro")
            }
            .task {
                do {
                    let offerings = try await Purchases.shared.offerings()
                    if let offering = offerings.offering(identifier: Self.offeringIdentifier) {
                        offeringsState = .loaded(offering)
                    } else {
                        offeringsState = .failed(OfferingError.notFound)
                    }
                } catch {
                    offeringsState = .failed(error)
                }
            }
            .multilineTextAlignment(.center)
        }

        enum OfferingError: LocalizedError {
            case notFound

            var errorDescription: String? {
                switch self {
                case .notFound:
                    return "Offering '\(OpenDefaultPackageVisibility.offeringIdentifier)' not found"
                }
            }
        }
    }
}
