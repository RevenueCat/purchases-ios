import RevenueCat
// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 An ad checkpoint: the dashboard resolves the checkpoint to an ad step, and the registered `adPresenter`
 shows the ad. An interstitial passes once it is dismissed. A rewarded ad passes only when the customer
 earned its reward, so closing it early keeps the customer here, like a dismissed paywall would.
 */
struct AdCheckpointView: View {
    private enum AdKind: String, CaseIterable, Identifiable {
        case interstitial = "Interstitial"
        case rewarded = "Rewarded"

        var id: Self { self }

        var checkpointIdentifier: String {
            switch self {
            case .interstitial: CheckpointIdentifiers.interstitialAd
            case .rewarded: CheckpointIdentifiers.rewardedAd
            }
        }
    }

    @Environment(UserViewModel.self) private var userViewModel

    @State private var adKind = AdKind.interstitial
    @State private var isRunning = false
    @State private var status = "Pick an ad kind and run the checkpoint."
    @State private var balances: [String: Int] = [:]

    private var activeEntitlements: [String] {
        userViewModel.customerInfo?.entitlements.active.keys.sorted() ?? []
    }

    var body: some View {
        List {
            Section {
                Picker("Ad kind", selection: $adKind) {
                    ForEach(AdKind.allCases) { kind in
                        Text(kind.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                Button("Run checkpoint \"\(adKind.checkpointIdentifier)\"", action: runCheckpoint)
                    .disabled(isRunning)
            } footer: {
                Text("Create a checkpoint with this identifier in the dashboard and give it an ad step.")
            }

            Section("Latest result") {
                Text(status)
                    .foregroundStyle(.secondary)
            }

            Section("Customer") {
                if activeEntitlements.isEmpty {
                    Text("No active entitlements")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeEntitlements, id: \.self) { identifier in
                        LabeledContent(identifier, value: "active")
                    }
                }
                if balances.isEmpty {
                    Text("No virtual currency balances")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(balances.keys.sorted(), id: \.self) { code in
                        LabeledContent(code, value: "\(balances[code] ?? 0)")
                    }
                }
            }
        }
        .navigationTitle("Ad checkpoint")
        .task { await refreshBalances() }
    }

    private func runCheckpoint() {
        isRunning = true
        status = "Running…"
        let identifier = adKind.checkpointIdentifier

        Purchases.shared.checkpoint(
            identifier,
            errorPresenter: { params, completion in
                isRunning = false
                status = "\"\(identifier)\" failed: \(params.error.localizedDescription)"
                completion.complete()
            },
            { result in
                isRunning = false
                status = result.flow == nil
                    ? "\"\(identifier)\" passed without presenting anything. Is it configured?"
                    : "\"\(identifier)\" passed."
                userViewModel.customerInfo = result.customer
                Task { await refreshBalances() }
            }
        )
    }

    private func refreshBalances() async {
        // A verified reward can change balances, and the SDK caches them.
        Purchases.shared.invalidateVirtualCurrenciesCache()
        guard let currencies = try? await Purchases.shared.virtualCurrencies() else { return }
        balances = currencies.all.mapValues(\.balance)
    }
}
