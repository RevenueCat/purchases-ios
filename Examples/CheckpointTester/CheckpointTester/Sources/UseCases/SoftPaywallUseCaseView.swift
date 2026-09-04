//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SoftPaywallUseCaseView.swift
//
//  Created by Rick van der Linden.
//

import Foundation
import RevenueCat
@_spi(CheckpointsInternal) import RevenueCatUI
import SwiftUI

struct SoftPaywallUseCaseView: View {

    @ObservedObject var customVariables: CustomVariables

    @State private var isRunning = false
    @State private var didLoad = false
    @State private var isSubscriber = false
    @State private var status = "Preparing the checkpoint…"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Feature content", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text("This content is always available, regardless of the checkpoint result.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Subscription status") {
                Text(self.isSubscriber ? "Subscriber" : "Free tier")
                Text(self.isRunning ? "Running the checkpoint…" : self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Run checkpoint again") {
                    Task { @MainActor in
                        await self.runCheckpoint()
                    }
                }
                .disabled(self.isRunning)
            }
        }
        .navigationTitle("Soft paywall")
        .task {
            guard !self.didLoad else { return }
            self.didLoad = true
            self.isSubscriber = Purchases.shared.cachedCustomerInfo?.entitlements.active.isEmpty == false
            await self.runCheckpoint()
        }
    }

    @MainActor
    private func runCheckpoint() async {
        guard !self.isRunning else { return }
        self.isRunning = true
        defer { self.isRunning = false }

        let result = await Purchases.shared.checkpoint(
            "soft_paywall",
            customVariables: self.customVariables.checkpointCustomVariables
        )
        self.handle(result)
    }

    @MainActor
    private func handle(_ result: CheckpointGateResult) {
        if !result.entitlements.isEmpty {
            self.isSubscriber = true
            self.status = "Access granted: \(result.entitlements.map(\.identifier).joined(separator: ", "))."
        } else if let reason = result.noActionReason {
            self.status = "No paywall shown (\(reason)). Content remains available."
        } else {
            self.status = "Paywall dismissed. Content remains available."
        }
    }

}
