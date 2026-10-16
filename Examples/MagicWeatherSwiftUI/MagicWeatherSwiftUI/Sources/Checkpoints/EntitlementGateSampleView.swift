//
//  EntitlementGateSampleView.swift
//  Magic Weather SwiftUI
//

import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 An entitlement gate: the app checks CustomerInfo first.
 It fires the checkpoint only when the customer has no active entitlement.
 */

struct EntitlementGateSampleView: View {

    @State private var didLoad = false
    @State private var activeEntitlementIdentifiers: [String] = []
    @State private var status = "Checking CustomerInfo…"

    private var hasAccess: Bool {
        return !self.activeEntitlementIdentifiers.isEmpty
    }

    var body: some View {
        List {
            Section("Active entitlements") {
                if self.hasAccess {
                    ForEach(self.activeEntitlementIdentifiers, id: \.self) { identifier in
                        Label(identifier, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("None")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Gate result") {
                Label(
                    self.hasAccess ? "Content unlocked" : "Content locked",
                    systemImage: self.hasAccess ? "lock.open.fill" : "lock.fill"
                )
                .font(.headline)
                .foregroundStyle(self.hasAccess ? .green : .red)

                Text(self.status)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Refresh access") {
                    Task { await self.refreshAccess() }
                }
            }
        }
        .navigationTitle("Entitlement gate")
        .task {
            guard !self.didLoad else { return }
            self.didLoad = true
            await self.refreshAccess()
        }
    }

    @MainActor
    private func refreshAccess() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.activeEntitlementIdentifiers = customerInfo.entitlements.active.keys.sorted()
        } catch {
            self.status = "Failed: \(error.localizedDescription)"
            return
        }

        guard !self.hasAccess else {
            self.status = "The app skipped the checkpoint because the customer already has access."
            return
        }

        Purchases.shared.checkpoint("entitlement_gate", customVariables: ["gate": .string("entitlement")]) { result in
            guard let flow = result.flow else {
                self.status = "No completed flow. The content stays locked."
                return
            }

            let obtained = flow.obtainedEntitlementIdentifiers
            self.activeEntitlementIdentifiers = Array(Set(self.activeEntitlementIdentifiers + obtained)).sorted()
            self.status = obtained.isEmpty
                ? "The flow completed without an active entitlement. The content stays locked."
                : "Obtained: \(obtained.joined(separator: ", "))."
        }
    }

}
