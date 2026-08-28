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
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct ContentView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var analyticsTracker: GlobalCheckpointAnalyticsTracker
    @StateObject private var customVariables = CustomVariables()
    @State private var isSubscriberAttributeEditorPresented = false

    var body: some View {
        TabView {
            self.demoList
                .tabItem {
                    Label("Use cases", systemImage: "list.bullet.rectangle")
                }

            self.variableEditor
                .tabItem {
                    Label("Custom variables", systemImage: "slider.horizontal.3")
                }

            self.listenerLog
                .tabItem {
                    Label("Listener", systemImage: "waveform.path.ecg")
                }
        }
        .sheet(isPresented: self.$isSubscriberAttributeEditorPresented) {
            SubscriberAttributeEditor()
                .presentationDetents([.medium])
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
                Section("App-driven use cases") {
                    NavigationLink {
                        HardPaywallUseCaseView(customVariables: self.customVariables)
                    } label: {
                        DemoLabel(
                            title: "Hard paywall",
                            subtitle: "Keeps content locked unless this checkpoint returns purchased or restored.",
                            systemImage: "lock.fill"
                        )
                    }

                    NavigationLink {
                        SoftPaywallUseCaseView(customVariables: self.customVariables)
                    } label: {
                        DemoLabel(
                            title: "Soft paywall",
                            subtitle: "Always shows the content and uses the result only to update its status.",
                            systemImage: "rectangle.portrait.and.arrow.right"
                        )
                    }

                    NavigationLink {
                        OnboardingUseCaseView(customVariables: self.customVariables)
                    } label: {
                        DemoLabel(
                            title: "Onboarding",
                            subtitle: "Runs a checkpoint before the final step and always completes.",
                            systemImage: "sparkles"
                        )
                    }

                    NavigationLink {
                        EntitlementGateUseCaseView(customVariables: self.customVariables)
                    } label: {
                        DemoLabel(
                            title: "Entitlement gate",
                            subtitle: "Checks CustomerInfo first and skips the checkpoint for subscribers.",
                            systemImage: "person.badge.key.fill"
                        )
                    }

                    NavigationLink {
                        CustomCheckpointUseCaseView(
                            model: self.model,
                            customVariables: self.customVariables
                        )
                    } label: {
                        DemoLabel(
                            title: "Custom checkpoint",
                            subtitle: "Enter any checkpoint identifier and hit it.",
                            systemImage: "text.cursor"
                        )
                    }
                }

                Section("Checkpoint outcomes") {
                    DemoButton(
                        title: "Unknown checkpoint",
                        subtitle: "An unknown identifier resolves without presenting UI.",
                        systemImage: "arrow.forward"
                    ) {
                        Task { @MainActor in
                            do {
                                let result = try await Purchases.shared.checkpoint(
                                    "this-checkpoint-does-not-exist",
                                    customVariables: self.customVariables.checkpointCustomVariables
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
                                    customVariables: self.customVariables.checkpointCustomVariables
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
            .subscriberAttributeToolbar(isPresented: self.$isSubscriberAttributeEditorPresented)
        }
    }

    private var variableEditor: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(self.$customVariables.variables) { $variable in
                        HStack {
                            TextField("Name", text: $variable.name)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            TextField("Value", text: $variable.value)
                        }
                    }
                    .onDelete { offsets in
                        self.customVariables.variables.remove(atOffsets: offsets)
                    }

                    Button {
                        self.customVariables.variables.append(.init())
                    } label: {
                        Label("Add variable", systemImage: "plus")
                    }
                } header: {
                    Text("Custom variables")
                } footer: {
                    Text("These custom variables are passed to every checkpoint call.")
                }
            }
            .navigationTitle("Custom variables")
            .subscriberAttributeToolbar(isPresented: self.$isSubscriberAttributeEditorPresented)
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
            .subscriberAttributeToolbar(isPresented: self.$isSubscriberAttributeEditorPresented)
        }
    }

}

private extension View {

    func subscriberAttributeToolbar(isPresented: Binding<Bool>) -> some View {
        self.toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresented.wrappedValue = true
                } label: {
                    Label("Set subscriber attribute", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }

}

private struct DemoButton: View {

    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            DemoLabel(
                title: self.title,
                subtitle: self.subtitle,
                systemImage: self.systemImage
            )
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

}

private struct DemoLabel: View {

    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
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

}
