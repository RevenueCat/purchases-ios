//
//  ConfigurationView.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/25/22.
//

import SwiftUI

import RevenueCat

struct ConfigurationView: View {

    struct Data {
        var apiKey: String = Constants.apiKey.replacingOccurrences(of: "REVENUECAT_API_KEY",
                                                                   with: "")
        var proxy: String = ""
        var storeKit2Enabled: Bool = true
    }

    @State
    private var data: Data = .init()

    let onContinue: (Data) -> Void

    var body: some View {
        Form {
            Section(header: Text("Configuration")) {
                TextField("API Key (required)", text: self.$data.apiKey)

                TextField("Proxy URL (optional)", text: self.$data.proxy)
            }

            Section {
                Toggle(isOn: self.$data.storeKit2Enabled) {
                    Text("StoreKit2 enabled")
                }
            }

            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Purchases.frameworkVersion)
                }
            }
        }

        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .navigationTitle("Purchase Tester")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.onContinue(self.data)
                } label: {
                    Text("Continue")
                }
                .disabled(!self.contentIsValid)
            }
        }
    }

    private var contentIsValid: Bool {
        let apiKeyIsValid = !self.data.apiKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        let proxyIsValid = self.data.proxy
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        || URL(string: self.data.proxy) != nil

        return apiKeyIsValid && proxyIsValid
    }

}

// MARK: -

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConfigurationView { _ in }
        }
    }
}
