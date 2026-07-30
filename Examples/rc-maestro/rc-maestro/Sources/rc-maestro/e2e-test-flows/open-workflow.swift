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

        static let defaultOfferingIdentifier = "default_workflows"

        /// The offering this flow renders. E2E tests can point it at a different one with the
        /// `offering_id` launch argument.
        static var offeringIdentifier: String {
            return UserDefaults.standard.string(forKey: "offering_id") ?? Self.defaultOfferingIdentifier
        }

        /// Whether to show the controls E2E tests use to change SDK state without relaunching, which
        /// would reset it. Off unless the `e2e_controls` launch argument is set, so that the flows which
        /// don't need them see this screen unchanged.
        static var showsE2EControls: Bool {
            return UserDefaults.standard.bool(forKey: "e2e_controls")
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

        enum GetOfferingsState {
            case loading
            case loaded(Offering)
            case failed(Error)
        }

        @State private var offeringsState: GetOfferingsState = .loading
        @State private var presentPaywall = false
        @State private var completedSyncCount = 0

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

                if Self.showsE2EControls {
                    self.e2eControls
                }
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

        @ViewBuilder
        private var e2eControls: some View {
            Button("Force Config Killswitch") {
                ForceServerErrorStrategyStore.update(to: .remoteConfigKillswitch)
            }

            // Config is only refreshed on foreground when its cache is stale, which no flow waits out, so
            // tests drive the refresh through this instead.
            Button("Sync Attributes And Offerings") {
                Task { await self.syncAndReloadOffering() }
            }

            Text("completed syncs: \(self.completedSyncCount)")
        }

        /// Syncs, then waits for the kill switch to land before reloading the offering: the config request
        /// runs concurrently with the sync's own offerings fetch, so the offerings it hands back can still
        /// carry the paywall components that config is about to prune.
        @MainActor
        private func syncAndReloadOffering() async {
            _ = try? await Purchases.shared.syncAttributesAndOfferingsIfNeeded()

            let deadline = Date().addingTimeInterval(10)
            while Purchases.shared.remoteConfigEnabled, Date() < deadline {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            if let offerings = try? await Purchases.shared.offerings(),
               let offering = offerings.offering(identifier: Self.offeringIdentifier) {
                self.offeringsState = .loaded(offering)
            }

            self.completedSyncCount += 1
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
