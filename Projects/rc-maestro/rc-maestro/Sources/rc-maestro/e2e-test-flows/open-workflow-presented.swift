//
//  open-workflow-presented.swift
//  Maestro
//
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

extension E2ETestFlowView {
    /// Opens the workflow paywall via the `.presentPaywall(offering:)` modifier rather than a raw
    /// `PaywallView` sheet. This is the exit-offer-aware presentation path: it surfaces a configured
    /// workflow exit offer when the paywall is dismissed (from the exit-offer step) without a purchase.
    struct OpenWorkflowPresented: View {

        static let offeringIdentifier = "default_workflows"

        enum GetOfferingsState {
            case loading
            case loaded(Offering)
            case failed(Error)
        }

        @State private var offeringsState: GetOfferingsState = .loading
        @State private var presentedOffering: Offering?

        var body: some View {
            VStack {
                Text("Workflow paywall (presented)")
                    .font(.largeTitle)

                switch offeringsState {
                case .loading:
                    Text("Loading offerings...")
                case .loaded(let offering):
                    Button("Present Paywall") {
                        presentedOffering = offering
                    }
                    .buttonStyle(.borderedProminent)
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }

                EntitlementView(identifier: "pro")
            }
            .presentPaywall(offering: $presentedOffering)
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
                    return "Offering '\(OpenWorkflowPresented.offeringIdentifier)' not found"
                }
            }
        }
    }
}
