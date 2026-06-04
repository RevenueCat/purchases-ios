//
//  ConfigurationFormView.swift
//  RCTTester
//

import SwiftUI

struct ConfigurationFormView: View {

    @Binding var configuration: SDKConfiguration
    let onConfigure: () -> Void

    var body: some View {
        Form {
            Section {
                TextField("API Key", text: $configuration.apiKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(.system(.body, design: .monospaced))
            } header: {
                Text("RevenueCat API Key")
            } footer: {
                Text("Your RevenueCat API key. Can also be set via Local.xcconfig.")
            }

            Section {
                TextField("App User ID", text: $configuration.appUserID)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } header: {
                Text("App User ID")
            } footer: {
                Text("Leave empty to let the SDK generate an anonymous user ID.")
            }

            Section {
                Picker("StoreKit Version", selection: $configuration.storeKitVersion) {
                    ForEach(SDKConfiguration.StoreKitVersion.allCases) { version in
                        Text(version.displayName).tag(version)
                    }
                }
            } header: {
                Text("StoreKit Version")
            } footer: {
                Text("Which StoreKit version the SDK should use for purchases.")
            }

            Section {
                Picker("Purchases Completed By", selection: $configuration.purchasesAreCompletedBy) {
                    ForEach(SDKConfiguration.PurchasesCompletedBy.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
            } header: {
                Text("Purchases Are Completed By")
            } footer: {
                Text(purchasesCompletedByFooter)
            }

            if configuration.purchasesAreCompletedBy == .myApp {
                Section {
                    Picker("Purchase Logic", selection: $configuration.purchaseLogic) {
                        ForEach(SDKConfiguration.PurchaseLogic.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } header: {
                    Text("Purchase Logic")
                } footer: {
                    Text(purchaseLogicFooter)
                }
            }

            Section {
                Button(action: onConfigure) {
                    HStack {
                        Spacer()
                        Text("Configure SDK")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(configuration.apiKey.isEmpty)
            }
        }
        .navigationTitle("RCTTester Setup")
    }

    private var purchasesCompletedByFooter: String {
        switch configuration.purchasesAreCompletedBy {
        case .revenueCat:
            return "All purchases are done through RevenueCat's purchase methods. RevenueCat will also finish transactions after successful receipt posting."
        case .myApp:
            return "The app is responsible for finishing transactions (also known as 'Observer Mode')."
        }
    }

    private var purchaseLogicFooter: String {
        switch configuration.purchaseLogic {
        case .throughRevenueCat:
            return "The app still uses the Purchases.shared.purchase() methods to make purchases."
        case .usingStoreKitDirectly:
            return "The app takes care of making the purchases using StoreKit APIs directly."
        }
    }
}

#Preview {
    NavigationView {
        ConfigurationFormView(
            configuration: .constant(.default),
            onConfigure: {}
        )
    }
}
