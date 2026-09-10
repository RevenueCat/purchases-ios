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

    @ObservedObject var model: CheckpointDemoModel
    @ObservedObject var customVariables: CustomVariables

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
                Text(self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Run checkpoint again") {
                    Task { @MainActor in
                        await self.runCheckpoint()
                    }
                }
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
        Purchases.shared.checkpoint(
            "soft_paywall",
            customVariables: self.customVariables.checkpointCustomVariables,
            paywallPresenter: self.model.localPaywallPresenter
        ) { result in
            guard let result else {
                self.status = "No completed flow. Content remains available."
                return
            }

            let obtained = result.obtainedEntitlements.map(\.entitlement.identifier).sorted()
            self.isSubscriber = self.isSubscriber || !obtained.isEmpty
            self.status = obtained.isEmpty
                ? "Checkpoint completed. Content remains available."
                : "Obtained: \(obtained.joined(separator: ", "))."
        }
    }

}
