//
//  AppContentView.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    private enum Tab {
        case examples
        case livePaywalls
        case settings
    }

    @State
    private var selectedTab: Tab = Purchases.isConfigured ? .livePaywalls : .examples

    @ObservedObject
    private var settings = DebugSettingsStore.shared

    var body: some View {
        TabView(selection: $selectedTab) {

            if Purchases.isConfigured {
                APIKeyDashboardList()
                    // Rebuild against the freshly configured instance after an API key swap.
                    .id(settings.configurationGeneration)
                    .tabItem {
                        Label("Live Paywalls", systemImage: "testtube.2")
                    }
                    .tag(Tab.livePaywalls)
            }

            #if !os(macOS)
            SamplePaywallsList()
                .tabItem {
                    Image("logo")
                        .renderingMode(.template)
                    Text("Examples")
                }
                .tag(Tab.examples)
            #endif

            // Always available so the API key can be set even from a "not configured" state.
            DebugSettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
    }

}

private struct DebugSettingsView: View {

    @ObservedObject var settings: DebugSettingsStore

    @State private var apiKeyDraft: String = ""
    @State private var showAppliedConfirmation: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("API Key", text: $apiKeyDraft)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                } header: {
                    Text("RevenueCat API Key")
                } footer: {
                    Text("Leave empty to use the build default. Applied now and on next launch.")
                }

                Section {
                    Button("Apply") {
                        settings.apiKeyOverride = apiKeyDraft
                        settings.apply()
                        showAppliedConfirmation = true
                    }

                    Button("Reset to default", role: .destructive) {
                        settings.resetToDefault()
                        apiKeyDraft = settings.apiKeyOverride
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear { apiKeyDraft = settings.apiKeyOverride }
        .alert("Configuration applied", isPresented: $showAppliedConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Purchases was reconfigured with the entered API key.")
        }
    }

}
