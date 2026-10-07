//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointsView.swift
//
//  Created by Rick van der Linden.
//

#if os(iOS) && !targetEnvironment(macCatalyst)

import Foundation
import RevenueCat
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

struct CheckpointsView: View {

    @FocusState private var isIdentifierFocused: Bool
    @State private var identifier = ""
    @State private var recentIdentifiers: [String]
    @State private var variables = [CheckpointVariable()]
    @State private var result: CheckpointResult?
    @State private var isSubscriberAttributeEditorPresented = false

    init() {
        self._recentIdentifiers = .init(initialValue: RecentCheckpointIdentifiers.load())
    }

    private var trimmedIdentifier: String {
        return self.identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var customVariables: [String: CustomVariableValue] {
        var result: [String: CustomVariableValue] = [:]
        for variable in self.variables {
            let key = variable.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            result[key] = .string(variable.value)
        }
        return result
    }

    var body: some View {
        NavigationView {
            Form {
                self.checkpointSection
                self.recentSection
                self.customVariablesSection
                self.resultSection
            }
            .navigationTitle("Checkpoints")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.isSubscriberAttributeEditorPresented = true
                    } label: {
                        Label("Subscriber attributes", systemImage: "person.crop.circle.badge.plus")
                    }
                }
            }
            .sheet(isPresented: self.$isSubscriberAttributeEditorPresented) {
                SubscriberAttributeEditor()
            }
        }
    }

    private var checkpointSection: some View {
        Section {
            TextField("Checkpoint identifier", text: self.$identifier)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused(self.$isIdentifierFocused)
                .onSubmit(self.triggerCheckpoint)

            Button("Trigger checkpoint", action: self.triggerCheckpoint)
                .disabled(self.trimmedIdentifier.isEmpty)
        } footer: {
            Text("Runs the checkpoint with the custom variables below.")
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        if !self.recentIdentifiers.isEmpty {
            Section("Recent") {
                ForEach(self.recentIdentifiers, id: \.self) { identifier in
                    Button(identifier) {
                        self.identifier = identifier
                        self.isIdentifierFocused = true
                    }
                }
            }
        }
    }

    private var customVariablesSection: some View {
        Section {
            ForEach(self.$variables) { $variable in
                HStack {
                    TextField("Name", text: $variable.name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Value", text: $variable.value)
                }
            }
            .onDelete { offsets in
                self.variables.remove(atOffsets: offsets)
            }

            Button {
                self.variables.append(CheckpointVariable())
            } label: {
                Label("Add variable", systemImage: "plus")
            }
        } header: {
            Text("Custom variables")
        } footer: {
            Text("String values are used for the next checkpoint call. Empty names are ignored.")
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let result {
            Section("Latest result") {
                CheckpointResultRow(label: "Identifier", value: result.identifier)
                CheckpointResultRow(label: "Outcome", value: result.outcome)

                if let details = result.details {
                    Text(details)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @MainActor
    private func triggerCheckpoint() {
        let identifier = self.trimmedIdentifier
        guard !identifier.isEmpty else { return }

        self.isIdentifierFocused = false
        self.recordRecentIdentifier(identifier)
        self.result = .inProgress(identifier: identifier)

        Purchases.shared.checkpoint(
            identifier,
            customVariables: self.customVariables,
            errorPresenter: { params, completion in
                self.result = .failed(
                    identifier: params.checkpointIdentifier,
                    error: params.error
                )
                completion.complete(.continue)
            },
            { flowResult in
                guard self.result?.isFailure != true else { return }
                self.result = .completed(identifier: identifier, flowResult: flowResult)
            }
        )
    }

    private func recordRecentIdentifier(_ identifier: String) {
        self.recentIdentifiers = RecentCheckpointIdentifiers.record(
            identifier,
            currentIdentifiers: self.recentIdentifiers
        )
    }

}

private enum RecentCheckpointIdentifiers {

    private static let userDefaultsKey = "PaywallsTester.recentCheckpointIdentifiers"

    static func load() -> [String] {
        return UserDefaults.standard.stringArray(forKey: Self.userDefaultsKey) ?? []
    }

    static func record(_ identifier: String, currentIdentifiers: [String]) -> [String] {
        let identifiers = [identifier] + currentIdentifiers.filter { $0 != identifier }
        let recentIdentifiers = Array(identifiers.prefix(5))
        UserDefaults.standard.set(recentIdentifiers, forKey: Self.userDefaultsKey)
        return recentIdentifiers
    }

}

private struct CheckpointVariable: Identifiable {

    let id = UUID()
    var name = ""
    var value = ""

}

private struct CheckpointResultRow: View {

    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(self.label)
            Spacer()
            Text(self.value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

}

private struct CheckpointResult {

    let identifier: String
    let outcome: String
    let details: String?
    let isFailure: Bool

    static func inProgress(identifier: String) -> Self {
        return Self(
            identifier: identifier,
            outcome: "Running",
            details: "Waiting for checkpoint presentation to finish.",
            isFailure: false
        )
    }

    static func completed(identifier: String, flowResult: FlowResult?) -> Self {
        guard let flowResult else {
            return Self(
                identifier: identifier,
                outcome: "No action",
                details: "No matching flow was presented, or the flow could not complete.",
                isFailure: false
            )
        }

        let identifiers = flowResult.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted()
        return Self(
            identifier: identifier,
            outcome: "Flow completed",
            details: identifiers.isEmpty
                ? "No new entitlements were granted."
                : "Granted entitlements: \(identifiers.joined(separator: ", ")).",
            isFailure: false
        )
    }

    static func failed(identifier: String, error: Error) -> Self {
        return Self(
            identifier: identifier,
            outcome: "Error",
            details: error.localizedDescription,
            isFailure: true
        )
    }

}

private struct SubscriberAttributeEditor: View {

    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @State private var value = ""

    private var trimmedKey: String {
        return self.key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Attribute key", text: self.$key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Attribute value", text: self.$value)
                } footer: {
                    Text(
                        "Subscriber attributes persist independently and affect checkpoint rule matching. " +
                        "Unset sends an empty string for this key."
                    )
                }
            }
            .navigationTitle("Subscriber attribute")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }

                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Unset", role: .destructive) {
                        self.updateAttribute(value: "")
                    }
                    .disabled(self.trimmedKey.isEmpty)

                    Button("Set") {
                        self.updateAttribute(value: self.value)
                    }
                    .disabled(self.trimmedKey.isEmpty)
                }
            }
        }
    }

    private func updateAttribute(value: String) {
        Purchases.shared.attribution.setAttributes([self.trimmedKey: value])
        self.dismiss()
    }

}

#endif
