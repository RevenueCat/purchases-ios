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
// The configured checkpoint list reads an internal SDK method, so it's Debug-only.
#if DEBUG
@_spi(Internal) @testable import RevenueCat
#else
import RevenueCat
#endif
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

struct CheckpointsView: View {

    @FocusState private var isIdentifierFocused: Bool
    @State private var identifier = ""
    @State private var recentIdentifiers: [String]
    @State private var configuredIdentifiers: [String] = []
    @State private var variables = [CheckpointVariable()]
    @State private var result: CheckpointDisplayResult?
    @State private var checkpointCompleted = false
    // Retries share an ID because the SDK can skip a retry while an earlier call is still presented.
    // Reset or completion invalidates callbacks from that test.
    @State private var testID = UUID()
    @State private var latestRequestID = UUID()
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
                self.protectedContentSection
                self.resultSection
                self.recentSection
                #if DEBUG
                self.configuredSection
                #endif
                self.customVariablesSection
            }
            .navigationTitle("Checkpoints")
            #if DEBUG
            .task { await self.loadConfiguredIdentifiers() }
            .refreshable { await self.loadConfiguredIdentifiers() }
            #endif
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

    #if DEBUG
    private var configuredSection: some View {
        Section {
            ForEach(self.configuredIdentifiers, id: \.self) { identifier in
                Button(identifier) {
                    self.triggerCheckpoint(identifier)
                }
                .contextMenu { self.presentationModeMenu(for: identifier) }
            }

            // The SDK throws for this identifier in Debug builds, to test error presentation.
            Button("Simulated error") {
                self.triggerCheckpoint(Self.simulatedErrorIdentifier)
            }
            .contextMenu { self.presentationModeMenu(for: Self.simulatedErrorIdentifier) }
        } header: {
            Text("Configured")
        } footer: {
            Text(
                self.configuredIdentifiers.isEmpty
                    ? "No checkpoints loaded for this project. Pull to refresh."
                    : "Checkpoints in this project. Tap one to run it, or long press to pick how it is presented."
            )
        }
    }

    private static let simulatedErrorIdentifier = "f0rc3_3rr0r"

    private func loadConfiguredIdentifiers() async {
        self.configuredIdentifiers = await Purchases.shared.checkpointIds()
    }
    #endif

    private var checkpointSection: some View {
        Section {
            TextField("Checkpoint identifier", text: self.$identifier)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused(self.$isIdentifierFocused)
                .onSubmit { self.triggerCheckpoint(self.trimmedIdentifier) }

            Button("Open protected content") { self.triggerCheckpoint(self.trimmedIdentifier) }
                .contextMenu { self.presentationModeMenu(for: self.trimmedIdentifier) }
                .disabled(self.trimmedIdentifier.isEmpty)
        } footer: {
            Text("Runs the checkpoint with the custom variables below.")
        }
    }

    private var protectedContentSection: some View {
        Section("Protected content") {
            Label(
                self.checkpointCompleted ? "Checkpoint completed" : "Locked · Not completed",
                systemImage: self.checkpointCompleted ? "lock.open.fill" : "lock.fill"
            )
            .font(.headline)
            .foregroundStyle(self.checkpointCompleted ? .green : .secondary)

            if self.checkpointCompleted {
                Text("Your premium library")
                    .font(.headline)
                Text(
                    "You can read this content because the checkpoint callback ran. " +
                    "A soft checkpoint can grant access without a purchase."
                )
                .foregroundStyle(.secondary)
            } else {
                Text("Run a checkpoint to open this content. Closing an unmet hard gate keeps it locked.")
                    .foregroundStyle(.secondary)
            }

            Button("Reset test", action: self.resetTest)
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
        Section("Latest result") {
            if let result {
                CheckpointResultRow(label: "Identifier", value: result.identifier)
                HStack {
                    Text("Outcome")
                    Spacer()
                    Text(result.outcome)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                if let details = result.details {
                    Text(details)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Open protected content to see the checkpoint result here.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func presentationModeMenu(for identifier: String) -> some View {
        Button("Default") { self.triggerCheckpoint(identifier, presentationMode: .default) }
        Button("Full screen") { self.triggerCheckpoint(identifier, presentationMode: .modalFullScreen) }
        Button("Sheet") { self.triggerCheckpoint(identifier, presentationMode: .modalSheet) }
    }

    @MainActor
    private func triggerCheckpoint(_ identifier: String, presentationMode: FlowPresentationMode = .default) {
        guard !identifier.isEmpty else { return }

        self.isIdentifierFocused = false
        self.recordRecentIdentifier(identifier)
        let currentTestID = self.testID
        let requestID = UUID()
        self.latestRequestID = requestID
        self.checkpointCompleted = false
        self.result = .waiting(identifier: identifier)

        Purchases.shared.checkpoint(
            identifier,
            customVariables: self.customVariables,
            presentationMode: presentationMode,
            errorPresenter: { params, completion in
                if currentTestID == self.testID, requestID == self.latestRequestID {
                    self.result = .failed(
                        identifier: params.checkpointIdentifier,
                        error: params.error
                    )
                }
                completion.complete()
            },
            { checkpointResult in
                guard currentTestID == self.testID else { return }
                self.testID = UUID()
                self.checkpointCompleted = true
                self.result = .completed(identifier: identifier, result: checkpointResult)
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

private extension CheckpointsView {

    @MainActor
    func resetTest() {
        self.testID = UUID()
        self.checkpointCompleted = false
        self.result = nil
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

private struct CheckpointDisplayResult {

    let identifier: String
    let outcome: String
    let details: String?

    static func waiting(identifier: String) -> Self {
        return Self(
            identifier: identifier,
            outcome: "No completion callback yet",
            details: "Content stays locked until the callback runs. You can retry or reset the test."
        )
    }

    static func completed(identifier: String, result: CheckpointResult) -> Self {
        let activeNow = result.customer.entitlements.active.keys.sorted()
        let activeNowDetails = "Active now: \(activeNow.isEmpty ? "none" : activeNow.joined(separator: ", "))."
        guard let flowResult = result.flow else {
            return Self(
                identifier: identifier,
                outcome: "Nothing presented",
                details: "See the logs for the reason. \(activeNowDetails)"
            )
        }

        let entitlements = flowResult.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted()
        let products = flowResult.obtainedProducts.map(\.product.productIdentifier).sorted()
        let obtainedDetails = entitlements.isEmpty && products.isEmpty
            ? "Nothing obtained."
            : "Obtained entitlements: \(entitlements.joined(separator: ", ")), " +
                "products: \(products.joined(separator: ", "))."
        return Self(
            identifier: identifier,
            outcome: "Flow presented",
            details: "\(obtainedDetails) \(activeNowDetails)"
        )
    }

    static func failed(identifier: String, error: Error) -> Self {
        return Self(
            identifier: identifier,
            outcome: "Error",
            details: error.localizedDescription
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
