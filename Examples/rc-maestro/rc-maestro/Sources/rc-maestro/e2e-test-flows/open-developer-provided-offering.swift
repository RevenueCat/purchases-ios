//
//  open-developer-provided-offering.swift
//  Maestro
//
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

extension E2ETestFlowView {
    /// Covers presenting a paywall with a developer-modified `Offering` instance.
    ///
    /// The flow loads the current offering, rebuilds it without the monthly package, and passes that
    /// copy to `PaywallView(offering:)`. The copy has no paywall or components attached, so it takes
    /// the workflow path, which must render the passed instance rather than re-fetching the offering
    /// by identifier. Only the annual card should appear.
    ///
    /// Selection isn't assertable from the rendered radio buttons, so the flow taps the purchase button
    /// and reports which package the SDK was about to buy. `onPurchaseInitiated` declines to proceed, so
    /// no StoreKit sheet appears and nothing covers the label the flow asserts on.
    struct OpenDeveloperProvidedOffering: View {

        static let removedPackageIdentifier = "$rc_monthly"

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
                Text("Developer-provided offering")
                    .font(.largeTitle)

                switch offeringsState {
                case .loading:
                    Text("Loading offerings...")
                case .loaded(let offering):
                    Text("packages: \(offering.availablePackages.map(\.identifier).joined(separator: ", "))")

                    Button("Present Paywall") {
                        presentPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $presentPaywall) {
                        PaywallView(offering: offering)
                            .onPurchaseInitiated { package, resume in
                                let identifier = package.identifier
                                Task { @MainActor in
                                    self.purchaseStartedPackage = identifier
                                    // Declining keeps StoreKit out of the flow entirely.
                                    resume(shouldProceed: false)
                                    // Declining does not dismiss the paywall, and while it is up it
                                    // covers the label the flow asserts on.
                                    self.presentPaywall = false
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
                    if let offering = offerings.current {
                        offeringsState = .loaded(Self.removingMonthlyPackage(from: offering))
                    } else {
                        offeringsState = .failed(OfferingError.noCurrentOffering)
                    }
                } catch {
                    offeringsState = .failed(error)
                }
            }
            .multilineTextAlignment(.center)
        }

        /// Rebuilds the offering through the public initializer, the same way an app would customize
        /// an offering before presenting it. The copy carries no paywall data.
        private static func removingMonthlyPackage(from offering: Offering) -> Offering {
            return Offering(
                identifier: offering.identifier,
                serverDescription: offering.serverDescription,
                metadata: offering.metadata,
                paywall: nil,
                availablePackages: offering.availablePackages.filter {
                    $0.identifier != Self.removedPackageIdentifier
                },
                webCheckoutUrl: offering.webCheckoutUrl
            )
        }

        enum OfferingError: LocalizedError {
            case noCurrentOffering

            var errorDescription: String? {
                switch self {
                case .noCurrentOffering:
                    return "No current offering configured"
                }
            }
        }
    }
}
