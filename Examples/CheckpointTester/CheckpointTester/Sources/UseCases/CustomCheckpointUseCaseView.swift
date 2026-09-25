//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomCheckpointUseCaseView.swift
//
//  Created by Rick van der Linden.
//

import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct CustomCheckpointUseCaseView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var customVariables: CustomVariables
    @ObservedObject private var rewardPollLog = RewardPollLog.shared

    @State private var identifier = ""
    @State private var status: String?

    private var trimmedIdentifier: String {
        return self.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                TextField("Checkpoint identifier", text: self.$identifier)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Hit") {
                    self.hitCheckpoint()
                }
                .disabled(self.trimmedIdentifier.isEmpty)
            } footer: {
                if let status {
                    Text(status)
                } else {
                    Text("The callback reports new entitlements after a presented flow completes.")
                }
            }

            if !self.rewardPollLog.lines.isEmpty {
                Section("Reward verification polling") {
                    ForEach(Array(self.rewardPollLog.lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .navigationTitle("Custom checkpoint")
    }

    @MainActor
    private func hitCheckpoint() {
        guard !self.trimmedIdentifier.isEmpty else { return }
        let identifier = self.trimmedIdentifier
        let paywallPresenter = self.model.localPaywallPresenter
        self.status = "Checkpoint requested."
        self.rewardPollLog.clear()

        Purchases.shared.checkpoint(
            identifier,
            customVariables: self.customVariables.checkpointCustomVariables,
            paywallPresenter: paywallPresenter
        ) { result in
            Task { @MainActor in
                self.status = Self.describe(result)
            }
        }
    }

    private static func describe(_ result: FlowResult?) -> String {
        guard let result else {
            return "No flow was presented or the flow could not complete."
        }

        if let adOutcome = result.adOutcome {
            return "Ad outcome: \(adOutcome)."
        }

        let entitlementIdentifiers = result.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted()
        guard !entitlementIdentifiers.isEmpty else {
            return "Checkpoint flow completed without granting a new entitlement."
        }
        return "New entitlements: \(entitlementIdentifiers.joined(separator: ", "))."
    }

}
