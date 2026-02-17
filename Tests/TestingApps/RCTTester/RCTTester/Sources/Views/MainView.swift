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
                    OfferingsListView(purchaseManager: purchaseManager)
                } label: {
                    Label("View Offerings", systemImage: "tag")
                }
            }
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
                }
            }
        }
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
