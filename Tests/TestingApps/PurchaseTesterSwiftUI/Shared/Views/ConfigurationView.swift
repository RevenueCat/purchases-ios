//
//  ConfigurationView.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/25/22.
//

import SwiftUI

import Core
import RevenueCat

struct ConfigurationView: View {

    struct Data: Equatable, Codable {
        var apiKey: String = Constants.apiKey.replacingOccurrences(of: "REVENUECAT_API_KEY",
                                                                   with: "")
        var proxy: String = ""
        var storeKit2Enabled: Bool = true
        var verificationMode: Configuration.EntitlementVerificationMode = .disabled
        var observerMode: Bool = false
    }

    let onContinue: (Data) -> Void

    init(onContinue: @escaping (Data) -> Void) {
        self.onContinue = onContinue

        if let data = self.storedData,
           let decoded = try? JSONDecoder().decode(Data.self, from: data) {
            self._data = .init(initialValue: decoded)
        }
    }

    var body: some View {
        if #available(iOS 16.0, macOS 13.0, watchOS 9.0, *) {
            self.form.formStyle(.grouped)
        } else {
            self.form
        }
    }

    private var form: some View {
        Form {
            Section(header: Text("Configuration")) {
                TextField("API Key (required)", text: self.$data.apiKey)

                TextField("Proxy URL (optional)", text: self.$data.proxy)
            }

            Section(header: Text("Settings")) {
                Picker("Entitlement Verification", selection: self.$data.verificationMode) {
                    ForEach(Configuration.EntitlementVerificationMode.all) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                Toggle(isOn: self.$data.storeKit2Enabled) {
                    Text("StoreKit2 enabled")
                }

                Toggle(isOn: self.$data.observerMode) {
                    Text("Observer mode")
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
        #if !os(macOS)
        .textInputAutocapitalization(.never)
        #endif
        .autocorrectionDisabled(true)
        .navigationTitle("Purchase Tester")
        .toolbar {
            ToolbarItem(placement: self.buttonPlacement) {
                Button {
                    self.saveData()
                    self.onContinue(self.data)
                } label: {
                    Text("Continue")
                }
                #if !os(watchOS)
                .keyboardShortcut(.return)
                #endif
                .disabled(!self.contentIsValid)
            }
        }
        .onChange(of: self.data) { _ in
            self.saveData()
        }
    }

    // MARK: -

    @State
    private var data: Data = .init() {
        didSet {
            self.saveData()
        }
    }

    @AppStorage("com.revenuecat.sampleapp.data")
    private var storedData: Foundation.Data?
    
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

    private func saveData() {
        self.storedData = try? JSONEncoder().encode(self.data)
    }

    private var buttonPlacement: ToolbarItemPlacement {
        #if os(macOS) || os(watchOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }

}

extension Configuration.EntitlementVerificationMode: Codable {}

// MARK: -

struct ConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConfigurationView { _ in }
        }
    }
}
