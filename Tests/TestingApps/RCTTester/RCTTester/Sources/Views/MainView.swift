//
//  MainView.swift
//  RCTTester
//

import SwiftUI

struct MainView: View {

    @Binding var configuration: SDKConfiguration
    let purchaseManager: AnyPurchaseManager
    let onReconfigure: () -> Void

    @State private var showingConfigurationSheet = false
    @State private var editingConfiguration: SDKConfiguration = .default
    @State private var isRestoringPurchases = false
    @State private var restoreResultMessage: String?
    @State private var showingRestoreAlert = false

    var body: some View {
        List {
            Section("SDK Configuration") {
                ConfigurationSummaryView(configuration: $configuration)
            }

            Section("User") {
                UserSummaryView(configuration: $configuration)
            }

            Section("Offerings") {
                NavigationLink {
                    OfferingsListView(
                        configuration: configuration,
                        purchaseManager: purchaseManager
                    )
                } label: {
                    Label("View Offerings", systemImage: "tag")
                }
            }

            Section("Purchases") {
                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    HStack {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                        Spacer()
                        if isRestoringPurchases {
                            ProgressView()
                        }
                    }
                }
                .disabled(isRestoringPurchases)
            }
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreResultMessage ?? "")
        }
        .navigationTitle("RCTTester")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reconfigure") {
                    editingConfiguration = configuration
                    showingConfigurationSheet = true
                }
            }
        }
        .sheet(isPresented: $showingConfigurationSheet) {
            NavigationView {
                ConfigurationFormView(
                    configuration: $editingConfiguration,
                    onConfigure: {
                        configuration = editingConfiguration
                        showingConfigurationSheet = false
                        onReconfigure()
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingConfigurationSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Configure") {
                            configuration = editingConfiguration
                            showingConfigurationSheet = false
                            onReconfigure()
                        }
                        .disabled(editingConfiguration.apiKey.isEmpty)
                    }
                }
            }
        }
    }

    private func restorePurchases() async {
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            let result = try await purchaseManager.restorePurchases()
            if result.purchasesRecovered {
                restoreResultMessage = "Purchases restored successfully."
            } else {
                restoreResultMessage = "Restore completed, but no purchases were found."
            }
        } catch {
            restoreResultMessage = "Restore failed: \(error.localizedDescription)"
        }

        showingRestoreAlert = true
    }
}

#Preview {
    NavigationView {
        MainView(
            configuration: .constant(.default),
            purchaseManager: AnyPurchaseManager(RevenueCatPurchaseManager()),
            onReconfigure: {}
        )
    }
}
