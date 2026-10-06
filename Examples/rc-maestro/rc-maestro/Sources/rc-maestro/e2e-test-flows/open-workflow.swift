//
//  open-workflow.swift
//  Maestro
//
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
@_spi(Internal) import RevenueCat
import RevenueCatUI

extension E2ETestFlowView {
    struct OpenWorkflow: View {

        /// A launch-argument override lets Maestro target isolated workflow fixtures without
        /// coupling those tests to the default workflow's dashboard configuration.
        static var offeringIdentifier: String {
            return UserDefaults.standard.string(forKey: "workflow_offering_identifier") ?? "default_workflows"
        }

        /// Custom paywall variable overrides read from a launch argument (used by E2E tests). Empty when
        /// `custom_users_count` is not provided, so the workflow renders the dashboard default value.
        static var customVariableOverrides: [String: CustomVariableValue] {
            guard let raw = UserDefaults.standard.string(forKey: "custom_users_count"),
                  let value = Double(raw) else {
                return [:]
            }
            return ["users_count": .number(value)]
        }

        /// Comma-separated app user ids. Each one gets a button that logs in as it and reloads the offering.
        static var logInAppUserIDs: [String] {
            return UserDefaults.standard.string(forKey: "log_in_app_user_ids")?
                .split(separator: ",")
                .map(String.init) ?? []
        }

        enum GetOfferingsState {
            case loading
            case loaded(Offering)
            case failed(Error)
        }

        @State private var offeringsState: GetOfferingsState = .loading
        @State private var presentPaywall = false
        @State private var loggedInAppUserID: String?

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

                ForEach(Self.logInAppUserIDs, id: \.self) { appUserID in
                    Button("Log In as \(appUserID)") {
                        Task {
                            _ = try? await Purchases.shared.logIn(appUserID)
                            await loadOffering()
                            loggedInAppUserID = appUserID
                        }
                    }
                }
                if let loggedInAppUserID {
                    Text("Logged in as \(loggedInAppUserID)")
                }

                EntitlementView(identifier: "pro")

            }
            .task {
                await loadOffering()
            }
            .multilineTextAlignment(.center)
        }

        private func loadOffering() async {
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
