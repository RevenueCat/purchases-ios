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
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct SoftPaywallUseCaseView: View {

    @ObservedObject var customVariables: CustomVariables

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
                customVariables: self.customVariables.checkpointCustomVariables
            )
            self.handle(result)
        } catch {
            self.status = "Checkpoint failed: \(error.localizedDescription). Content remains available."
        }
    }

    @MainActor
    private func handle(_ result: CheckpointResult) {
        switch result {
        case let presented as CheckpointResult.PaywallPresented:
            self.handle(presented.paywallOutcome)
        case let received as CheckpointResult.ReceivedOffering:
            self.status = "Received offering '\(received.offering.identifier)'. The app owns what happens next."
        case let noAction as CheckpointResult.NoAction:
            self.status = "No paywall shown (\(noAction.reason)). Content remains available."
        default:
            self.status = "Unknown checkpoint result. Content remains available."
        }
    }

    @MainActor
    private func handle(_ outcome: CheckpointPaywallOutcome) {
        switch outcome {
        case let purchased as CheckpointPaywallOutcome.Purchased:
            self.updateSubscriptionStatus(with: purchased.customerInfo, action: "Purchased")
        case let restored as CheckpointPaywallOutcome.Restored:
            self.updateSubscriptionStatus(with: restored.customerInfo, action: "Restored")
        case is CheckpointPaywallOutcome.Dismissed:
            self.status = "Paywall dismissed. Content remains available."
        case is CheckpointPaywallOutcome.WebCheckoutOpened:
            self.status = "Web checkout opened. Content remains available."
        case let failed as CheckpointPaywallOutcome.Error:
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
