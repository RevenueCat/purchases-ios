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

import SwiftUI

struct ContentView: View {

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var analyticsTracker: GlobalCheckpointAnalyticsTracker

    var body: some View {
        self.demoList
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
                        self.model.runCheckpoint(identifier: "result_picker")
                    }

                    DemoButton(
                        title: "No match",
                        subtitle: "An unknown identifier resolves without presenting UI.",
                        systemImage: "arrow.forward"
                    ) {
                        self.model.runCheckpoint(identifier: "unknown_checkpoint")
                    }

                    DemoButton(
                        title: "Simulated error",
                        subtitle: "The checkpoint call throws a configuration error.",
                        systemImage: "exclamationmark.triangle"
                    ) {
                        self.model.runCheckpoint(identifier: "error_checkpoint")
                    }
                }

                Section("Paywalls") {
                    DemoButton(
                        title: "Soft paywall",
                        subtitle: "Can be dismissed without purchasing.",
                        systemImage: "rectangle.portrait.and.arrow.right"
                    ) {
                        self.model.runCheckpoint(identifier: "soft_paywall")
                    }

                    DemoButton(
                        title: "Hard paywall",
                        subtitle: "Interactive dismissal is disabled.",
                        systemImage: "lock.fill"
                    ) {
                        self.model.runCheckpoint(identifier: "hard_paywall")
                    }
                }

                Section("Onboarding") {
                    DemoButton(
                        title: "Onboarding workflow",
                        subtitle: "Completes a multi-step flow and displays the checkpoint result.",
                        systemImage: "sparkles"
                    ) {
                        self.model.runCheckpoint(identifier: "onboarding")
                    }
                }

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
            .navigationTitle("Checkpoint Tester")
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
