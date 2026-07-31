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
        @State private var configEndpointKillSwitchOn = false

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

                self.e2eControls
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

        /// Controls E2E tests use to change SDK state without relaunching, which would reset it.
        @ViewBuilder
        private var e2eControls: some View {
            Button("Force Config Killswitch") {
                ForceServerErrorStrategyStore.update(to: .remoteConfigKillswitch)
            }

            // Config is only refreshed on foreground when its cache is stale, which no flow waits out, so
            // tests drive the refresh through this instead.
            Button("Sync Attributes And Offerings") {
                Task { await self.syncAndWaitForKillSwitch() }
            }

            if self.configEndpointKillSwitchOn {
                Text("config killswitch: on")
            }
        }

        /// Drives the config request that returns the kill switch, then waits for it to land so the flow
        /// doesn't have to sleep.
        @MainActor
        private func syncAndWaitForKillSwitch() async {
            _ = try? await Purchases.shared.syncAttributesAndOfferingsIfNeeded()

            let deadline = Date().addingTimeInterval(10)
            while Purchases.shared.remoteConfigEnabled {
                // Returning without reporting makes the flow waiting on the label fail here rather than
                // later, on a paywall assertion that can't say why the kill switch never landed.
                guard Date() < deadline else { return }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            self.configEndpointKillSwitchOn = true
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
