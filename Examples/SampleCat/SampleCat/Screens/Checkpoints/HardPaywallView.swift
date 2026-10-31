import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 A hard paywall: the content stays locked until the customer in the checkpoint result has access.
 */
struct HardPaywallView: View {
    @State private var didLoad = false
    @State private var hasAccess = false
    @State private var status = "Preparing the checkpoint…"

    var body: some View {
        List {
            Section {
                Label(hasAccess ? "Premium content unlocked" : "Premium content locked",
                      systemImage: hasAccess ? "lock.open.fill" : "lock.fill")
                    .font(.headline)
                    .foregroundStyle(hasAccess ? .green : .red)
            }

            Section("Latest result") {
                Text(status)
                    .foregroundStyle(.secondary)
            }

            if !hasAccess {
                Section {
                    Button("Try again", action: runCheckpoint)
                }
            }
        }
        .navigationTitle("Hard paywall")
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            runCheckpoint()
        }
    }

    private func runCheckpoint() {
        Purchases.shared.checkpoint(CheckpointIdentifiers.hardPaywall,
                                    customVariables: ["gate": .string("hard")]) { result in
            // Decide on the customer in the result. It also covers a customer who already had access.
            hasAccess = result.customer.hasPremiumAccess
            if hasAccess {
                status = "The customer has access. The content is unlocked."
            } else {
                status = result.flow == nil
                    ? "No flow was presented. The content stays locked."
                    : "The flow ended without access. The content stays locked."
            }
        }
    }
}
