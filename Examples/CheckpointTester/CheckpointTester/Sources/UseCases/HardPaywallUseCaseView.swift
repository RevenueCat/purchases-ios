//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HardPaywallUseCaseView.swift
//
//  Created by Rick van der Linden.
//

import Foundation
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct HardPaywallUseCaseView: View {

    @ObservedObject var customVariables: CustomVariables

    @State private var isRunning = false
    @State private var didLoad = false
    @State private var attempts = 0
    @State private var hasAccess = false
    @State private var status = "Preparing the checkpoint…"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        self.hasAccess ? "Premium content unlocked" : "Premium content locked",
                        systemImage: self.hasAccess ? "lock.open.fill" : "lock.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(self.hasAccess ? .green : .red)

                    Text(
                        self.hasAccess
                            ? "This checkpoint returned purchased or restored, so the gated content is available."
                            : "Only a purchased or restored result from this checkpoint unlocks the content."
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Latest result") {
                Text(self.isRunning ? "Running the checkpoint…" : self.status)
                    .foregroundStyle(.secondary)
            }

            if !self.hasAccess {
                Section {
                    Button("Try again") {
                        Task { @MainActor in
                            await self.runCheckpoint()
                        }
                    }
                    .disabled(self.isRunning)
                }
            }
        }
        .navigationTitle("Hard paywall")
        .task {
            guard !self.didLoad else { return }
            self.didLoad = true
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
                "hard_paywall",
                customVariables: self.customVariablesForNextAttempt()
            )
            self.handle(result)
        } catch {
            self.status = "Failed: \(error.localizedDescription)"
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
            self.status = "No paywall shown (\(noAction.reason)). Content remains locked."
        default:
            self.status = "Unknown checkpoint result. Content remains locked."
        }
    }

    @MainActor
    private func handle(_ outcome: CheckpointPaywallOutcome) {
        switch outcome {
        case is CheckpointPaywallOutcome.Purchased:
            self.hasAccess = true
            self.status = "Purchase completed. Access granted."
        case is CheckpointPaywallOutcome.Restored:
            self.hasAccess = true
            self.status = "Restore completed. Access granted."
        case is CheckpointPaywallOutcome.Dismissed:
            self.status = "Paywall dismissed. Content remains locked."
        case is CheckpointPaywallOutcome.WebCheckoutOpened:
            self.status = "Web checkout opened. Complete the purchase to unlock content."
        case let failed as CheckpointPaywallOutcome.Error:
            self.status = "Paywall failed: \(failed.error.localizedDescription)"
        default:
            self.status = "Unknown paywall outcome. Content remains locked."
        }
    }

    @MainActor
    private func customVariablesForNextAttempt() -> [String: CustomVariableValue] {
        self.attempts += 1
        var customVariables = self.customVariables.checkpointCustomVariables
        customVariables["gate"] = .string("hard")
        customVariables["attempt"] = .number(Double(self.attempts))
        return customVariables
    }

}
