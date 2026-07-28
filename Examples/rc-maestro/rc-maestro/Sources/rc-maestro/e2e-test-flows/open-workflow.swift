//
//  open-workflow.swift
//  Maestro
//
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

extension E2ETestFlowView {
    struct OpenWorkflow: View {

        static let offeringIdentifier = "default_workflows"

        /// Custom paywall variable overrides read from a launch argument (used by E2E tests). Empty when
        /// `custom_users_count` is not provided, so the workflow renders the dashboard default value.
        static var customVariableOverrides: [String: CustomVariableValue] {
            guard let raw = UserDefaults.standard.string(forKey: "custom_users_count"),
                  let value = Double(raw) else {
                return [:]
            }
            return ["users_count": .number(value)]
        }

        enum GetOfferingsState {
            case loading
            case loaded(Offering)
            case failed(Error)
        }

        @State private var offeringsState: GetOfferingsState = .loading
        @State private var presentPaywall = false

        var body: some View {
            VStack {
                Text("Workflow paywall")
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
                    }
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
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
                    return "Offering '\(OpenWorkflow.offeringIdentifier)' not found"
                }
            }
        }
    }
}
