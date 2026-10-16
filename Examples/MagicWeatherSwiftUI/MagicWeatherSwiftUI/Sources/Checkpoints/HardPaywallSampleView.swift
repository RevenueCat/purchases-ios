//
//  HardPaywallSampleView.swift
//  Magic Weather SwiftUI
//

import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 A hard paywall: the content stays locked until the checkpoint result has an active entitlement.
 */

struct HardPaywallSampleView: View {

    @State private var didLoad = false
    @State private var hasAccess = false
    @State private var status = "Preparing the checkpoint…"

    var body: some View {
        List {
            Section {
                Label(
                    self.hasAccess ? "Premium content unlocked" : "Premium content locked",
                    systemImage: self.hasAccess ? "lock.open.fill" : "lock.fill"
                )
                .font(.headline)
                .foregroundStyle(self.hasAccess ? .green : .red)
            }

            Section("Latest result") {
                Text(self.status)
                    .foregroundStyle(.secondary)
            }

            if !self.hasAccess {
                Section {
                    Button("Try again", action: self.runCheckpoint)
                }
            }
        }
        .navigationTitle("Hard paywall")
        .onAppear {
            guard !self.didLoad else { return }
            self.didLoad = true
            self.runCheckpoint()
        }
    }

    private func runCheckpoint() {
        Purchases.shared.checkpoint("hard_paywall", customVariables: ["gate": .string("hard")]) { result in
            let obtained = result.flow?.obtainedEntitlementIdentifiers ?? []
            guard !obtained.isEmpty else {
                self.status = result.flow == nil
                    ? "No completed flow. The content stays locked."
                    : "The flow completed without an active entitlement. The content stays locked."
                return
            }

            self.hasAccess = true
            self.status = "Obtained: \(obtained.joined(separator: ", ")). The content is unlocked."
        }
    }

}
