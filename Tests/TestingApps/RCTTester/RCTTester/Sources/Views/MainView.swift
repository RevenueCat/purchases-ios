//
//  MainView.swift
//  RCTTester
//

import SwiftUI

struct MainView: View {

    @Binding var configuration: SDKConfiguration
    let onReconfigure: () -> Void

    @State private var showingConfigurationSheet = false
    @State private var editingConfiguration: SDKConfiguration = .default

    var body: some View {
        VStack {
            ConfigurationSummaryView(configuration: configuration)

            Text("🚧 Work in progress...").padding()
            Spacer()
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
        MainView(configuration: .constant(.default), onReconfigure: {})
    }
}
