import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 An entitlement gate: the app checks CustomerInfo first.
 It fires the checkpoint only when the customer has no access.
 */
struct EntitlementGateView: View {
    @State private var didLoad = false
    @State private var hasAccess = false
    @State private var status = "Checking CustomerInfo…"

    var body: some View {
        List {
            Section("Gate result") {
                Label(hasAccess ? "Content unlocked" : "Content locked",
                      systemImage: hasAccess ? "lock.open.fill" : "lock.fill")
                    .font(.headline)
                    .foregroundStyle(hasAccess ? .green : .red)

                Text(status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Refresh access") {
                    Task { await refreshAccess() }
                }
            }
        }
        .navigationTitle("Entitlement gate")
        .task {
            guard !didLoad else { return }
            didLoad = true
            await refreshAccess()
        }
    }

    private func refreshAccess() async {
        do {
            hasAccess = try await Purchases.shared.customerInfo().hasPremiumAccess
        } catch {
            status = "Failed: \(error.localizedDescription)"
            return
        }

        guard !hasAccess else {
            status = "The app skipped the checkpoint because the customer already has access."
            return
        }

        Purchases.shared.checkpoint(CheckpointIdentifiers.entitlementGate,
                                    customVariables: ["gate": .string("entitlement")]) { result in
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
