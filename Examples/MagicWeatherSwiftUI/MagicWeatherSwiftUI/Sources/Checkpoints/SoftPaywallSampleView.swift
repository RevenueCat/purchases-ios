//
//  SoftPaywallSampleView.swift
//  Magic Weather SwiftUI
//

import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 A soft paywall: the content is always available, and the checkpoint result only updates the status.
 */

struct SoftPaywallSampleView: View {

    @State private var didLoad = false
    @State private var isSubscriber = false
    @State private var status = "Preparing the checkpoint…"

    var body: some View {
        List {
            Section {
                Label("Feature content", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text("This content is always available, for each checkpoint result.")
                    .foregroundStyle(.secondary)
            }

            Section("Subscription status") {
                Text(self.isSubscriber ? "Subscriber" : "Free tier")
                Text(self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Run the checkpoint again", action: self.runCheckpoint)
            }
        }
        .navigationTitle("Soft paywall")
        .onAppear {
            guard !self.didLoad else { return }
            self.didLoad = true
            self.isSubscriber = Purchases.shared.cachedCustomerInfo?.entitlements.active.isEmpty == false
            self.runCheckpoint()
        }
    }

    private func runCheckpoint() {
        Purchases.shared.checkpoint("soft_paywall") { result in
            guard let flow = result.flow else {
                self.status = "No completed flow. The content stays available."
                return
            }

            let obtained = flow.obtainedEntitlementIdentifiers
            self.isSubscriber = self.isSubscriber || !obtained.isEmpty
            self.status = obtained.isEmpty
                ? "The flow completed. The content stays available."
                : "Obtained: \(obtained.joined(separator: ", "))."
        }
    }

}
