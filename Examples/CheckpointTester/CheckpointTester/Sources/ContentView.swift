//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ContentView.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat
@_spi(Internal) import RevenueCatUI
import SwiftUI

struct ContentView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var analyticsTracker: GlobalCheckpointAnalyticsTracker
    @State private var checkpointVariables = [
        CheckpointVariable(name: "source", value: "CheckpointTester"),
    ]

    var body: some View {
        TabView {
            self.demoList
                .tabItem {
                    Label("Use cases", systemImage: "list.bullet.rectangle")
                }

            self.variableEditor
                .tabItem {
                    Label("Variables", systemImage: "slider.horizontal.3")
                }

            self.listenerLog
                .tabItem {
                    Label("Listener", systemImage: "waveform.path.ecg")
                }
        }
        .alert(
            isPresented: Binding(
                get: { self.model.outcomeAlert != nil },
                set: { isPresented in
                    if !isPresented {
                        self.model.outcomeAlertDismissed()
                    }
                }
            )
        ) {
            Alert(
                title: Text(self.model.outcomeAlert?.title ?? "Checkpoint result"),
                message: Text(self.model.outcomeAlert?.message ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var demoList: some View {
        NavigationStack {
            List {
                Section("Checkpoint outcomes") {
                    DemoButton(
                        title: "Mock checkpoint UI",
                        subtitle: "Choose purchased, restored, dismissed, or error.",
                        systemImage: "rectangle.on.rectangle"
                    ) {
                        Task { @MainActor in
                            do {
                                let result = try await Purchases.shared.checkpoint(
                                    "result_picker",
                                    params: self.checkpointParams
                                )
                                self.model.showOutcome(result)
                            } catch {
                                self.model.showError(error)
                            }
                        }
                    }

                    DemoButton(
                        title: "No match",
                        subtitle: "An unknown identifier resolves without presenting UI.",
                        systemImage: "arrow.forward"
                    ) {
                        Task { @MainActor in
                            do {
                                let result = try await Purchases.shared.checkpoint(
                                    "unknown_checkpoint",
                                    params: self.checkpointParams
                                )
                                self.model.showOutcome(result)
                            } catch {
                                self.model.showError(error)
                            }
                        }
                    }

                    DemoButton(
                        title: "Simulated error",
                        subtitle: "The checkpoint call throws a configuration error.",
                        systemImage: "exclamationmark.triangle"
                    ) {
                        Task { @MainActor in
                            do {
                                let result = try await Purchases.shared.checkpoint(
                                    "error_checkpoint",
                                    params: self.checkpointParams
                                )
                                self.model.showOutcome(result)
                            } catch {
                                self.model.showError(error)
                            }
                        }
                    }
                }

                Section("Paywalls") {
                    DemoButton(
                        title: "Soft paywall",
                        subtitle: "Can be dismissed without purchasing.",
                        systemImage: "rectangle.portrait.and.arrow.right"
                    ) {
                        Task { @MainActor in
                            do {
                                let result = try await Purchases.shared.checkpoint(
                                    "soft_paywall",
                                    params: self.checkpointParams
                                )
                                self.model.showOutcome(result)
                            } catch {
                                self.model.showError(error)
                            }
                        }
                    }

                    DemoButton(
                        title: "Hard paywall",
                        subtitle: "Interactive dismissal is disabled.",
                        systemImage: "lock.fill"
                    ) {
                        Task { @MainActor in
                            do {
                                let result = try await Purchases.shared.checkpoint(
                                    "hard_paywall",
                                    params: self.checkpointParams
                                )
                                self.model.showOutcome(result)
                            } catch {
                                self.model.showError(error)
                            }
                        }
                    }
                }

                Section("Onboarding") {
                    DemoButton(
                        title: "Onboarding workflow",
                        subtitle: "Completes a multi-step flow and displays the checkpoint result.",
                        systemImage: "sparkles"
                    ) {
                        Task { @MainActor in
                            do {
                                let result = try await Purchases.shared.checkpoint(
                                    "onboarding",
                                    params: self.checkpointParams
                                )
                                self.model.showOutcome(result)
                            } catch {
                                self.model.showError(error)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Checkpoint Tester")
        }
    }

    private var variableEditor: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(self.$checkpointVariables) { $variable in
                        HStack {
                            TextField("Name", text: $variable.name)
                            TextField("Value", text: $variable.value)
                        }
                    }
                    .onDelete { offsets in
                        self.checkpointVariables.remove(atOffsets: offsets)
                    }

                    Button {
                        self.checkpointVariables.append(.init())
                    } label: {
                        Label("Add variable", systemImage: "plus")
                    }
                } header: {
                    Text("Checkpoint variables")
                } footer: {
                    Text("These custom properties are passed to every checkpoint call.")
                }
            }
            .navigationTitle("Variables")
        }
    }

    private var listenerLog: some View {
        NavigationStack {
            List {
                Section {
                    if self.analyticsTracker.events.isEmpty {
                        Text("Global listener events will appear here as checkpoints run.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(
                        Array(self.analyticsTracker.events.enumerated()),
                        id: \.offset
                    ) { _, event in
                        Text(event)
                            .font(.caption.monospaced())
                    }

                    if !self.analyticsTracker.events.isEmpty {
                        Button("Clear event log", role: .destructive) {
                            self.analyticsTracker.clearEvents()
                        }
                    }
                } header: {
                    Text("Global checkpoint listener")
                } footer: {
                    Text("A global analytics tracker can observe checkpoint hits and completed results here.")
                }
            }
            .navigationTitle("Global Listener")
        }
    }

    private var checkpointParams: CheckpointParams {
        var customProperties: [String: RevenueCat.CheckpointValue] = [:]

        for variable in self.checkpointVariables {
            let name = variable.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                customProperties[name] = .string(variable.value)
            }
        }

        return CheckpointParams(customProperties: customProperties)
    }

}

private struct CheckpointVariable: Identifiable {

    let id = UUID()
    var name = ""
    var value = ""

}

private struct DemoButton: View {

    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Label {
                VStack(alignment: .leading, spacing: 3) {
                    Text(self.title)
                        .font(.headline)
                    Text(self.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: self.systemImage)
                    .frame(width: 28)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

}
