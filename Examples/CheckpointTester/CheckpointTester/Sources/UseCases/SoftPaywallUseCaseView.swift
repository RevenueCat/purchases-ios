//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SoftPaywallUseCaseView.swift
//
//  Created by Rick van der Linden.
//

import Foundation
import RevenueCat
import RevenueCatUI
import SwiftUI

struct SoftPaywallUseCaseView: View {

    @ObservedObject var checkpointVariables: CheckpointVariables

    @State private var isRunning = false
    @State private var didLoad = false
    @State private var isSubscriber = false
    @State private var status = "Preparing the checkpoint…"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Feature content", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("This content is always available, regardless of the checkpoint result.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Subscription status") {
                Text(self.isSubscriber ? "Subscriber" : "Free tier")
                Text(self.isRunning ? "Running the checkpoint…" : self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Run checkpoint again") {
                    Task { @MainActor in
                        await self.runCheckpoint()
                    }
                }
                .disabled(self.isRunning)
            }
        }
        .navigationTitle("Soft paywall")
        .task {
            guard !self.didLoad else { return }
            self.didLoad = true
            self.isSubscriber = Purchases.shared.cachedCustomerInfo?.entitlements.active.isEmpty == false
            await self.runCheckpoint()
        }
    }

    @MainActor
    private func runCheckpoint() async {
        guard !self.isRunning else { return }
        self.isRunning = true
        defer { self.isRunning = false }

        do {
            let result = try await Purchases.shared.checkpoint(
                "soft_paywall",
                params: self.checkpointVariables.checkpointParams
            )
            self.handle(result)
        } catch {
            self.status = "Checkpoint failed: \(error.localizedDescription). Content remains available."
        }
    }

    @MainActor
    private func handle(_ result: CheckpointResult) {
        switch result {
        case let presented as CheckpointPaywallPresentedResult:
            self.handle(presented.paywallOutcome)
        case let noAction as CheckpointNoActionResult:
            self.status = "No paywall shown (\(noAction.reason.value)). Content remains available."
        default:
            self.status = "Unknown checkpoint result. Content remains available."
        }
    }

    @MainActor
    private func handle(_ outcome: CheckpointPaywallOutcome) {
        switch outcome {
        case let purchased as CheckpointPaywallPurchasedOutcome:
            self.updateSubscriptionStatus(with: purchased.customerInfo, action: "Purchased")
        case let restored as CheckpointPaywallRestoredOutcome:
            self.updateSubscriptionStatus(with: restored.customerInfo, action: "Restored")
        case is CheckpointPaywallDismissedOutcome:
            self.status = "Paywall dismissed. Content remains available."
        case let failed as CheckpointPaywallErrorOutcome:
            self.status = "Paywall failed: \(failed.error.localizedDescription)"
        default:
            self.status = "Unknown paywall outcome. Content remains available."
        }
    }

    @MainActor
    private func updateSubscriptionStatus(with customerInfo: CustomerInfo, action: String) {
        self.isSubscriber = !customerInfo.entitlements.active.isEmpty
        self.status = "\(action). Content remains available."
    }

}
