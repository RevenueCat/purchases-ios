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
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

struct CustomCheckpointUseCaseView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var customVariables: CustomVariables
    @ObservedObject private var checkpointLog = CheckpointDebugLog.shared

    @State private var identifier = ""
    @State private var status: String?
    @State private var presentationMode: FlowPresentationMode = .default

    private var trimmedIdentifier: String {
        return self.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                TextField("Checkpoint identifier", text: self.$identifier)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Picker("Presentation mode", selection: self.$presentationMode) {
                    ForEach(FlowPresentationMode.testerCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                Button("Hit") {
                    self.hitCheckpoint()
                }
                .disabled(self.trimmedIdentifier.isEmpty)
            } footer: {
                if let status {
                    Text(status)
                } else {
                    Text("This presentation mode applies only to this checkpoint invocation.")
                }
            }

            if !self.checkpointLog.lines.isEmpty {
                Section {
                    ForEach(Array(self.checkpointLog.lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                    }
                } header: {
                    HStack {
                        Text("Checkpoint log")
                        Spacer()
                        Button("Clear") {
                            self.checkpointLog.clear()
                        }
                        .font(.caption)
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
        self.checkpointLog.record("[\(identifier)] requested \(Self.timestamp())")

        Purchases.shared.checkpoint(
            identifier,
            customVariables: self.customVariables.checkpointCustomVariables,
            presentationMode: self.presentationMode,
            paywallPresenter: paywallPresenter,
            errorPresenter: self.model.localErrorPresenter
        ) { result in
            Task { @MainActor in
                let description = Self.describe(result)
                self.status = description
                self.checkpointLog.record("[\(identifier)] \(description) \(Self.timestamp())")
            }
        }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "(\(formatter.string(from: Date())))"
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
