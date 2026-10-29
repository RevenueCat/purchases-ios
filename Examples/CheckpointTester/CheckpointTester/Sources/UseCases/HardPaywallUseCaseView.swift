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
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

struct HardPaywallUseCaseView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var customVariables: CustomVariables

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
                            ? "The checkpoint callback ran, so the gated content is available."
                            : "Remote hard gating suppresses the callback until any configured entitlement is active."
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Latest result") {
                Text(self.status)
                    .foregroundStyle(.secondary)
            }

            if !self.hasAccess {
                Section {
                    Button("Try again") {
                        Task { @MainActor in
                            await self.runCheckpoint()
                        }
                    }
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
        Purchases.shared.checkpoint(
            "hard_paywall",
            customVariables: self.customVariablesForNextAttempt(),
            paywallPresenter: self.model.localPaywallPresenter,
            errorPresenter: self.model.localErrorPresenter
        ) { result in
            let obtained = result.flow?.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted() ?? []
            self.hasAccess = true
            self.status = obtained.isEmpty
                ? "Checkpoint callback ran. Content unlocked."
                : "Obtained: \(obtained.joined(separator: ", ")). Content unlocked."
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
