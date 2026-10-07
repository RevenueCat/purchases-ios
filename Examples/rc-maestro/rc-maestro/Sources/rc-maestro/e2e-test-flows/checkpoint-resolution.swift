//
//  checkpoint-resolution.swift
//  Maestro
//
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
import RevenueCat
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI

extension E2ETestFlowView {
    /// Hits a checkpoint through the public API with an app-owned paywall presenter, and shows what the SDK
    /// reported for each attempt: the offering it handed to the presenter, how many times it called the
    /// presenter, and the callback result. Every label carries the attempt number, so a late result from an
    /// earlier attempt cannot satisfy an assertion on the current one.
    struct CheckpointResolution: View {

        static let attributeKey = "should_use_custom_ui"
        static let purchaseOfferingIdentifier = "default"

        private struct PresentedPaywall: Identifiable {
            let attempt: Int
            let checkpointIdentifier: String
            let offeringIdentifier: String
            let completion: PaywallPresentationCompletion

            var id: Int { self.attempt }
        }

        @State private var isReady = false
        @State private var setupError: String?
        @State private var identifier = UserDefaults.standard.string(forKey: "checkpoint_identifier") ?? ""
        @State private var attributeValue: String?

        @State private var attempt = 0
        @State private var presenterInvocations = 0
        @State private var presentedOfferingIdentifier: String?
        @State private var callbackDescription = "pending"
        @State private var presentedPaywall: PresentedPaywall?

        @State private var purchaseStatus = "idle"

        var body: some View {
            ScrollView {
                VStack(spacing: 8) {
                    Text(self.statusDescription)
                    Text("app user id: \(Purchases.shared.appUserID)")
                        .font(.caption)

                    HStack {
                        TextField("Checkpoint identifier", text: self.$identifier)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("checkpoint_identifier")
                        Button("Clear") { self.identifier = "" }
                            .accessibilityIdentifier("checkpoint_identifier_clear")
                    }

                    Button("Hit Checkpoint") { self.hitCheckpoint() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!self.isReady)
                        .accessibilityIdentifier("checkpoint_hit")

                    if self.attempt > 0 {
                        Text("attempt \(self.attempt) presenter invocations: \(self.presenterInvocations)")
                        Text("attempt \(self.attempt) offering: \(self.presentedOfferingIdentifier ?? "none")")
                        Text("attempt \(self.attempt) callback: \(self.callbackDescription)")
                    }

                    Text("\(Self.attributeKey): \(self.attributeValue ?? "absent")")
                    HStack {
                        Button("Set true") { self.setAttribute("true") }
                            .accessibilityIdentifier("attribute_set_true")
                        Button("Set false") { self.setAttribute("false") }
                            .accessibilityIdentifier("attribute_set_false")
                        Button("Delete") { self.setAttribute(nil) }
                            .accessibilityIdentifier("attribute_delete")
                    }
                    .buttonStyle(.bordered)

                    Button("Purchase") { self.purchase() }
                        .buttonStyle(.bordered)
                        .disabled(!self.isReady)
                        .accessibilityIdentifier("purchase")
                    Text("purchase: \(self.purchaseStatus)")

                    EntitlementView(identifier: "pro")
                }
                .padding()
            }
            .multilineTextAlignment(.center)
            .sheet(item: self.$presentedPaywall) { paywall in
                VStack(spacing: 16) {
                    Text("presented checkpoint: \(paywall.checkpointIdentifier)")
                    Text("presented offering: \(paywall.offeringIdentifier)")
                    Button("Close") {
                        self.presentedPaywall = nil
                        paywall.completion(.closed)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("checkpoint_close")
                }
                .interactiveDismissDisabled()
            }
            .task {
                do {
                    _ = try await Purchases.shared.customerInfo()
                    _ = try await Purchases.shared.offerings()
                    self.isReady = true
                } catch {
                    self.setupError = error.localizedDescription
                }
            }
        }

        private var statusDescription: String {
            if let setupError { return "status: failed (\(setupError))" }
            return self.isReady ? "status: ready" : "status: loading"
        }

        @MainActor
        private func hitCheckpoint() {
            self.attempt += 1
            let attempt = self.attempt
            self.presenterInvocations = 0
            self.presentedOfferingIdentifier = nil
            self.callbackDescription = "pending"

            Purchases.shared.checkpoint(
                self.identifier,
                paywallPresenter: { params, completion in
                    guard attempt == self.attempt else { return }
                    self.presenterInvocations += 1
                    self.presentedOfferingIdentifier = params.offering.identifier
                    self.presentedPaywall = PresentedPaywall(
                        attempt: attempt,
                        checkpointIdentifier: params.checkpointIdentifier,
                        offeringIdentifier: params.offering.identifier,
                        completion: completion
                    )
                }
            ) { result in
                guard attempt == self.attempt else { return }
                self.callbackDescription = Self.describe(result)
            }
        }

        private static func describe(_ result: FlowResult?) -> String {
            guard let result else { return "nil" }
            let entitlements = result.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted()
            return "obtained [\(entitlements.joined(separator: ", "))]"
        }

        private func setAttribute(_ value: String?) {
            // An empty value deletes the attribute.
            Purchases.shared.attribution.setAttributes([Self.attributeKey: value ?? ""])
            self.attributeValue = value
        }

        private func purchase() {
            self.purchaseStatus = "in progress"
            Task {
                do {
                    let offerings = try await Purchases.shared.offerings()
                    guard let package = offerings.offering(identifier: Self.purchaseOfferingIdentifier)?
                        .availablePackages.first else {
                        self.purchaseStatus = "failed (no package in '\(Self.purchaseOfferingIdentifier)')"
                        return
                    }
                    let result = try await Purchases.shared.purchase(package: package)
                    if result.userCancelled {
                        self.purchaseStatus = "cancelled"
                    } else {
                        let active = result.customerInfo.entitlements.active.keys.sorted()
                        self.purchaseStatus = "completed, active [\(active.joined(separator: ", "))]"
                    }
                } catch {
                    self.purchaseStatus = "failed (\(error.localizedDescription))"
                }
            }
        }
    }
}
