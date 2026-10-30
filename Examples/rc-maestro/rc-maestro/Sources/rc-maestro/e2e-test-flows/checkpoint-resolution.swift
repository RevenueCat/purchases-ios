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
    /// With the `checkpoint_presenter` launch argument set to `sdk`, the SDK presents the flow itself, and
    /// the screen also shows what the flow obtained.
    struct CheckpointResolution: View {

        private struct PresentedPaywall: Identifiable {
            let offeringIdentifier: String
            let completion: PaywallPresentationCompletion

            var id: String { self.offeringIdentifier }
        }

        private let identifier = UserDefaults.standard.string(forKey: "checkpoint_identifier") ?? ""
        private let attribute = UserDefaults.standard.string(forKey: "checkpoint_attribute")
        private let usesSDKPresenter = UserDefaults.standard.string(forKey: "checkpoint_presenter") == "sdk"

        @State private var presenterInvocations = 0
        @State private var presentedOfferingIdentifier: String?
        @State private var callbackDescription = "pending"
        @State private var presentedPaywall: PresentedPaywall?
        @State private var resultDetails: [String] = []

        var body: some View {
            VStack(spacing: 8) {
                Text("presenter invocations: \(self.presenterInvocations)")
                Text("offering: \(self.presentedOfferingIdentifier ?? "none")")
                Text("callback: \(self.callbackDescription)")
                ForEach(self.resultDetails, id: \.self) { Text($0) }
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

            let appPresenter: PaywallPresentationHandler = { params, completion in
                self.presenterInvocations += 1
                self.presentedOfferingIdentifier = params.offering.identifier
                self.presentedPaywall = PresentedPaywall(
                    offeringIdentifier: params.offering.identifier,
                    completion: completion
                )
            }

            Purchases.shared.checkpoint(
                self.identifier,
                paywallPresenter: self.usesSDKPresenter ? nil : appPresenter
            ) { result in
                self.callbackDescription = result.flow == nil ? "nil" : "obtained"
                if self.usesSDKPresenter {
                    self.resultDetails = Self.details(of: result)
                }
            }
        }

        private static func details(of result: CheckpointResult) -> [String] {
            let entitlements = result.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier) ?? []
            let products = result.flow?.obtainedProducts.map(\.product.productIdentifier) ?? []
            let active = result.customer.entitlements.active.keys
            return [
                "obtained entitlements: \(Self.list(entitlements))",
                "obtained products: \(Self.list(products))",
                "entitlement \(Self.entitlementID) obtained: \(result.didObtainEntitlement(Self.entitlementID))",
                "product \(Self.productID) obtained: \(result.didObtainProduct(Self.productID))",
                "customer active entitlements: \(Self.list(active))"
            ]
        }

        private static func list<S: Sequence<String>>(_ values: S) -> String {
            let sorted = values.sorted()
            return sorted.isEmpty ? "none" : sorted.joined(separator: ", ")
        }

        private static let entitlementID = "pro"
        // The checkpoint paywall's preselected package.
        private static let productID = "pro_monthly_subscription"
    }
}
