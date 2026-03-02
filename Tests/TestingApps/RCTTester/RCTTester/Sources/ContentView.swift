//
//  ContentView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat

struct ContentView: View {

    @State private var configuration: SDKConfiguration
    @State private var purchaseManager: AnyPurchaseManager?
    @State private var hasStoredConfiguration: Bool

    private var isSDKConfigured: Bool {
        purchaseManager != nil
    }

    init() {
        let storedConfiguration = SDKConfiguration.load()
        _configuration = State(initialValue: storedConfiguration ?? .default)
        _hasStoredConfiguration = State(initialValue: storedConfiguration != nil)
    }

    var body: some View {
        NavigationView {
            if let purchaseManager {
                MainView(
                    configuration: $configuration,
                    purchaseManager: purchaseManager,
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

        builder = builder.with(appUserID: configuration.appUserID)

        switch configuration.purchasesAreCompletedBy {
        case .revenueCat:
            builder = builder.with(purchasesAreCompletedBy: .revenueCat, storeKitVersion: storeKitVersion)
        case .myApp:
            builder = builder.with(purchasesAreCompletedBy: .myApp, storeKitVersion: storeKitVersion)
        }

        Purchases.configure(with: builder.build())

        // Create the appropriate PurchaseManager based on configuration
        purchaseManager = .create(for: configuration)
    }
}

#Preview {
    ContentView()
}
