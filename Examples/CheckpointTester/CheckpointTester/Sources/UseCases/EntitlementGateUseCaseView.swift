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
@_spi(Checkpoints) import RevenueCatUI
import SwiftUI

struct EntitlementGateUseCaseView: View {

    @ObservedObject var checkpointVariables: CheckpointVariables

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
                params: self.entitlementCheckpointParams
            )
            self.handle(result)
        } catch {
            self.status = "Failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func handle(_ result: CheckpointResult) {
        switch result {
        case let presented as CheckpointPaywallPresentedResult:
            self.handle(presented.paywallOutcome)
        case let noAction as CheckpointNoActionResult:
            self.status = "No paywall shown (\(noAction.reason.value)). Content remains locked."
        default:
            self.status = "Unknown checkpoint result. Content remains locked."
        }
    }

    @MainActor
    private func handle(_ outcome: CheckpointPaywallOutcome) {
        switch outcome {
        case let purchased as CheckpointPaywallPurchasedOutcome:
            self.updateAccess(with: purchased.customerInfo, action: "Purchase completed")
        case let restored as CheckpointPaywallRestoredOutcome:
            self.updateAccess(with: restored.customerInfo, action: "Restore completed")
        case is CheckpointPaywallDismissedOutcome:
            self.status = "Paywall dismissed. Content remains locked."
        case let failed as CheckpointPaywallErrorOutcome:
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

    private var entitlementCheckpointParams: CheckpointParams {
        var customProperties = self.checkpointVariables.checkpointParams.customProperties
        customProperties["gate"] = .string("entitlement")
        return CheckpointParams(customProperties: customProperties)
    }

    private static func activeEntitlementIdentifiers(from customerInfo: CustomerInfo) -> [String] {
        return customerInfo.entitlements.active.keys.sorted()
    }

}
