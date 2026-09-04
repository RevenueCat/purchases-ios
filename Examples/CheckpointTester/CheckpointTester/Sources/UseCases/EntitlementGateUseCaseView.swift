//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementGateUseCaseView.swift
//
//  Created by Rick van der Linden.
//

import Foundation
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct EntitlementGateUseCaseView: View {

    @ObservedObject var customVariables: CustomVariables

    @State private var isRunning = false
    @State private var didLoad = false
    @State private var activeEntitlementIdentifiers: [String] = []
    @State private var status = "Checking CustomerInfo…"

    private var hasAccess: Bool {
        return !self.activeEntitlementIdentifiers.isEmpty
    }

    var body: some View {
        List {
            Section("Active entitlements") {
                if self.hasAccess {
                    ForEach(self.activeEntitlementIdentifiers, id: \.self) { identifier in
                        Label(identifier, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("None")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Gate result") {
                Label(
                    self.hasAccess ? "Content unlocked" : "Content locked",
                    systemImage: self.hasAccess ? "lock.open.fill" : "lock.fill"
                )
                .font(.headline)
                .foregroundStyle(self.hasAccess ? .green : .red)

                Text(self.isRunning ? "Checking access…" : self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Refresh access") {
                    Task { @MainActor in
                        await self.refreshAccess()
                    }
                }
                .disabled(self.isRunning)
            }
        }
        .navigationTitle("Entitlement gate")
        .task {
            guard !self.didLoad else { return }
            self.didLoad = true
            await self.refreshAccess()
        }
    }

    @MainActor
    private func refreshAccess() async {
        guard !self.isRunning else { return }
        self.isRunning = true
        defer { self.isRunning = false }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.activeEntitlementIdentifiers = Self.activeEntitlementIdentifiers(from: customerInfo)

            if self.hasAccess {
                self.status = "Checkpoint skipped because the customer already has access."
                return
            }

            let result = try await Purchases.shared.checkpoint(
                "entitlement_gate",
                customVariables: self.entitlementCheckpointCustomVariables
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
        case let purchased as CheckpointPaywallOutcome.Purchased:
            self.updateAccess(with: purchased.customerInfo, action: "Purchase completed")
        case let restored as CheckpointPaywallOutcome.Restored:
            self.updateAccess(with: restored.customerInfo, action: "Restore completed")
        case is CheckpointPaywallOutcome.Dismissed:
            self.status = "Paywall dismissed. Content remains locked."
        case is CheckpointPaywallOutcome.WebCheckoutOpened:
            self.status = "Web checkout opened. Refresh access after completing the purchase."
        case let failed as CheckpointPaywallOutcome.Error:
            self.status = "Paywall failed: \(failed.error.localizedDescription)"
        default:
            self.status = "Unknown paywall outcome. Content remains locked."
        }
    }

    @MainActor
    private func updateAccess(with customerInfo: CustomerInfo, action: String) {
        self.activeEntitlementIdentifiers = Self.activeEntitlementIdentifiers(from: customerInfo)
        self.status = self.hasAccess
            ? "\(action). Access granted."
            : "\(action), but no active entitlement was found."
    }

    private var entitlementCheckpointCustomVariables: [String: CustomVariableValue] {
        var customVariables = self.customVariables.checkpointCustomVariables
        customVariables["gate"] = .string("entitlement")
        return customVariables
    }

    private static func activeEntitlementIdentifiers(from customerInfo: CustomerInfo) -> [String] {
        return customerInfo.entitlements.active.keys.sorted()
    }

}
