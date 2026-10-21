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
    /// Hits the `checkpoint_identifier` launch argument once through the public API, with an app-owned
    /// paywall presenter, and shows what the SDK reported: the offering it handed to the presenter, how
    /// many times it called the presenter, and the callback result.
    ///
    /// The optional `checkpoint_attribute` launch argument sets `should_use_custom_ui` before the hit.
    struct CheckpointResolution: View {

        private struct PresentedPaywall: Identifiable {
            let offeringIdentifier: String
            let completion: PaywallPresentationCompletion

            var id: String { self.offeringIdentifier }
        }

        private let identifier = UserDefaults.standard.string(forKey: "checkpoint_identifier") ?? ""
        private let attribute = UserDefaults.standard.string(forKey: "checkpoint_attribute")

        @State private var presenterInvocations = 0
        @State private var presentedOfferingIdentifier: String?
        @State private var callbackDescription = "pending"
        @State private var presentedPaywall: PresentedPaywall?

        var body: some View {
            VStack(spacing: 8) {
                Text("presenter invocations: \(self.presenterInvocations)")
                Text("offering: \(self.presentedOfferingIdentifier ?? "none")")
                Text("callback: \(self.callbackDescription)")
            }
            .sheet(item: self.$presentedPaywall) { paywall in
                VStack(spacing: 16) {
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
            .task { self.hitCheckpoint() }
        }

        @MainActor
        private func hitCheckpoint() {
            if let attribute = self.attribute {
                Purchases.shared.attribution.setAttributes(["should_use_custom_ui": attribute])
            }

            Purchases.shared.checkpoint(
                self.identifier,
                paywallPresenter: { params, completion in
                    self.presenterInvocations += 1
                    self.presentedOfferingIdentifier = params.offering.identifier
                    self.presentedPaywall = PresentedPaywall(
                        offeringIdentifier: params.offering.identifier,
                        completion: completion
                    )
                }
            ) { result in
                self.callbackDescription = result == nil ? "nil" : "obtained"
            }
        }
    }
}
