//
//  ContentView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat

struct ContentView: View {

    @State private var configuration: SDKConfiguration
    @State private var isSDKConfigured = false
    @State private var hasStoredConfiguration: Bool

    init() {
        let storedConfiguration = SDKConfiguration.load()
        _configuration = State(initialValue: storedConfiguration ?? .default)
        _hasStoredConfiguration = State(initialValue: storedConfiguration != nil)
    }

    var body: some View {
        NavigationView {
            if isSDKConfigured {
                MainView(
                    configuration: $configuration,
                    onReconfigure: configureSDK
                )
            } else {
                ConfigurationFormView(
                    configuration: $configuration,
                    onConfigure: configureSDK
                )
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            if hasStoredConfiguration && !isSDKConfigured {
                configureSDK()
            }
        }
    }

    private func configureSDK() {
        configuration.save()

        Purchases.logLevel = .verbose

        let storeKitVersion: StoreKitVersion = configuration.storeKitVersion == .storeKit1
            ? .storeKit1
            : .storeKit2

        var builder = Configuration.Builder(withAPIKey: configuration.apiKey)

        switch configuration.purchasesAreCompletedBy {
        case .revenueCat:
            builder = builder.with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: storeKitVersion)
        case .myApp:
            builder = builder.with(purchasesAreCompletedBy: .myApp, storeKitVersion: storeKitVersion)
        }

        Purchases.configure(with: builder.build())
        isSDKConfigured = true
    }
}

#Preview {
    ContentView()
}
