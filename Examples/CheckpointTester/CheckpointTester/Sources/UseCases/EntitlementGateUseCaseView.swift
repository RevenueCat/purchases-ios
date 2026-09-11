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

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var customVariables: CustomVariables

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

                Text(self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Refresh access") {
                    Task { @MainActor in
                        await self.refreshAccess()
                    }
                }
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
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.activeEntitlementIdentifiers = Self.activeEntitlementIdentifiers(from: customerInfo)

            if self.hasAccess {
                self.status = "Checkpoint skipped because the customer already has access."
                return
            }

            Purchases.shared.checkpoint(
                "entitlement_gate",
                customVariables: self.entitlementCheckpointCustomVariables,
                paywallPresenter: self.model.localPaywallPresenter
            ) { result in
                self.handle(result)
            }
        } catch {
            self.status = "Failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func handle(_ result: CheckpointFlowResult?) {
        guard let result else {
            self.status = "No completed flow. Content remains locked."
            return
        }

        let obtained = result.obtainedEntitlements.map(\.entitlement.identifier).sorted()
        self.activeEntitlementIdentifiers = Array(Set(self.activeEntitlementIdentifiers + obtained)).sorted()
        self.status = obtained.isEmpty
            ? "Checkpoint completed without an active entitlement. Content remains locked."
            : "Obtained: \(obtained.joined(separator: ", "))."
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
