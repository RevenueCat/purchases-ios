//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdCheckpointUseCaseView.swift
//

import Foundation
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct AdCheckpointUseCaseView: View {

    /// Non-consumable test IAP purchased via khepri's Simulated (Test) Store app config,
    /// reached via the `test_`-prefixed API key in `Local.xcconfig` — purchasing it goes
    /// through `SimulatedStorePurchaseHandler`, not real StoreKit, so no Apple ID prompt.
    private static let lifetimeProductId = "lifetime_test"

    /// Drives the "never purchased" / "has purchased" checkpoint audiences server-side.
    /// `customerInfo.purchases` isn't wired into the local rules engine's dimension
    /// providers yet, so the audiences key off this subscriber attribute instead
    /// ("false"/"true"). It must always hold one of those two values, never be unset: the
    /// rules engine's `var` accessor throws `unresolvedVariable` for a genuinely-missing
    /// path instead of degrading to `null`, so an `isEmpty`-style audience can never match.
    private static let hasPurchasedAttributeKey = "has_bought_lifetime"

    @ObservedObject var customVariables: CustomVariables

    @AppStorage("checkpointTester.hasSeededPurchaseAttribute") private var hasSeededPurchaseAttribute = false

    @State private var isRunning = false
    @State private var status = "Tap \"Hit checkpoint\" to resolve the ad checkpoint."
    @State private var didLoad = false
    @State private var isPurchasing = false
    @State private var purchaseStatus =
        "Not purchased yet — the checkpoint should resolve the \"never purchased\" ad."

    var body: some View {
        List {
            Section("Latest result") {
                Text(self.isRunning ? "Running the checkpoint…" : self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Hit checkpoint") {
                    Task { @MainActor in
                        await self.runCheckpoint()
                    }
                }
                .disabled(self.isRunning)
            }

            Section("Purchase status") {
                Text(self.isPurchasing ? "Purchasing…" : self.purchaseStatus)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Buy Lifetime (test)") {
                    Task { @MainActor in
                        await self.buyLifetime()
                    }
                }
                .disabled(self.isPurchasing)

                Button("Reset (never purchased)", role: .destructive) {
                    Purchases.shared.attribution.setAttributes([Self.hasPurchasedAttributeKey: "false"])
                    self.purchaseStatus =
                        "Reset — the checkpoint should resolve the \"never purchased\" ad again."
                }
                .disabled(self.isPurchasing)
            }
        }
        .navigationTitle("Ad checkpoint")
        .task {
            guard !self.didLoad else { return }
            self.didLoad = true
            if !self.hasSeededPurchaseAttribute {
                Purchases.shared.attribution.setAttributes([Self.hasPurchasedAttributeKey: "false"])
                self.hasSeededPurchaseAttribute = true
            }
            await self.runCheckpoint()
        }
    }

    @MainActor
    private func buyLifetime() async {
        guard !self.isPurchasing else { return }
        self.isPurchasing = true
        defer { self.isPurchasing = false }

        let products = await Purchases.shared.products([Self.lifetimeProductId])
        guard let product = products.first else {
            self.purchaseStatus = "Product \(Self.lifetimeProductId) not found — check the Simulated Store configuration."
            return
        }

        do {
            let result = try await Purchases.shared.purchase(product: product)
            if result.userCancelled {
                self.purchaseStatus = "Purchase cancelled."
                return
            }
            Purchases.shared.attribution.setAttributes([Self.hasPurchasedAttributeKey: "true"])
            self.purchaseStatus = "Purchased! Re-running the checkpoint…"
            await self.runCheckpoint()
        } catch {
            self.purchaseStatus = "Purchase failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func runCheckpoint() async {
        guard !self.isRunning else { return }
        self.isRunning = true
        defer { self.isRunning = false }

        do {
            let result = try await Purchases.shared.checkpoint(
                "ad_checkpoint",
                customVariables: self.customVariables.checkpointCustomVariables
            )
            self.handle(result)
        } catch {
            self.status = "Failed: \(error.localizedDescription)"
        }
    }

    /// `RCAdmobAdapter.enableCheckpointAds()` (called once at app launch, in
    /// `CheckpointTesterApp.configurePurchases`) registered the AdMob handler for the `"admob"`
    /// mediator, so `checkpoint(_:)` already loaded, tracked, and presented the ad — and awaited its
    /// dismissal — before this ever runs. There's nothing left to do here but react to the outcome.
    @MainActor
    private func handle(_ result: CheckpointResult) {
        switch result {
        case let presented as CheckpointAdPresentedResult:
            self.handle(presented.outcome)
        case let adResult as CheckpointAdResult:
            self.status = "Resolved \(adResult.adUnitId) for mediator '\(adResult.mediator)', "
                + "but no handler is registered for it."
        case let noAction as CheckpointNoActionResult:
            self.status = "No ad shown (\(noAction.reason.description))."
        default:
            self.status = "Unknown checkpoint result."
        }
    }

    @MainActor
    private func handle(_ outcome: CheckpointAdOutcome) {
        switch outcome {
        case is CheckpointAdShownOutcome:
            self.status = "Ad shown and dismissed."
        case let failed as CheckpointAdFailedOutcome:
            self.status = "Ad failed: \(failed.error.localizedDescription)"
        default:
            self.status = "Unknown ad outcome."
        }
    }

}
