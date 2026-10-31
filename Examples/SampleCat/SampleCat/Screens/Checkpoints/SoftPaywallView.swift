import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 A soft paywall: the content is always available, and the checkpoint result only updates the status.
 */
struct SoftPaywallView: View {
    @State private var didLoad = false
    @State private var hasAccess = false
    @State private var status = "Preparing the checkpoint…"

    var body: some View {
        List {
            Section {
                Label("Feature content", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text("This content is available for each checkpoint result.")
                    .foregroundStyle(.secondary)
            }

            Section("Subscription status") {
                Text(hasAccess ? "Subscriber" : "Free tier")
                Text(status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Run the checkpoint again", action: runCheckpoint)
            }
        }
        .navigationTitle("Soft paywall")
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            runCheckpoint()
        }
    }

    private func runCheckpoint() {
        Purchases.shared.checkpoint(CheckpointIdentifiers.softPaywall) { result in
            hasAccess = result.customer.hasPremiumAccess
            status = result.flow == nil
                ? "No flow was presented. The content stays available."
                : "The flow ended. The content stays available."
        }
    }
}
