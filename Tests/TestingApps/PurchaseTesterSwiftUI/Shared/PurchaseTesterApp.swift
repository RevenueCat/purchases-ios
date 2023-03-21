//
//  PurchaseTesterApp.swift
//  Shared
//
//  Created by Josh Holtz on 1/10/22.
//

import Foundation
import SwiftUI

import Core
import RevenueCat

@main
struct PurchaseTesterApp: App {

    @State
    private var configuration: ConfiguredPurchases?
    
    @StateObject
    private var revenueCatCustomerData: RevenueCatCustomerData = .init()

    var body: some Scene {
        WindowGroup(id: Windows.default.rawValue) {
            Group {
                if let configuration {
                    NavigationSplitView {
                        ContentView(configuration: configuration)
                            .environmentObject(self.revenueCatCustomerData)
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Button {
                                        self.configuration = nil
                                    } label: {
                                        Text("Reconfigure")
                                    }
                                }
                            }
                    } detail: {
                        DynamicCustomerView(customerInfo: self.$revenueCatCustomerData.customerInfo)
                    }
                    .navigationSplitViewStyle(.balanced)
                    .navigationSplitViewColumnWidth(100)
                    .task(id: self.configuration?.purchases) {
                        self.revenueCatCustomerData.customerInfo = nil

                        if let configuration = self.configuration {
                            for await customerInfo in configuration.purchases.customerInfoStream {
                                self.revenueCatCustomerData.customerInfo = customerInfo
                                self.revenueCatCustomerData.appUserID = configuration.purchases.appUserID
                            }
                        }
                    }
                } else {
                    #if os(macOS)
                    self.configurationView
                    #else
                    NavigationView {
                        self.configurationView
                    }
                    #endif
                }
            }
            .navigationViewStyle(.automatic)
            .animation(.default, value: self.isConfigured)
            .transition(.opacity)
        }

        WindowGroup(id: Windows.logs.rawValue) {
            LoggerView(logger: ConfiguredPurchases.logger)
        }

        #if os(macOS)
        MenuBarExtra("ReceiptParser", systemImage: "doc.text.magnifyingglass") {
            VStack {
                ReceiptInspectorView()

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
                .padding()
            }
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 800, height: 1000)
        #endif

    }

    private var configurationView: some View {
        ConfigurationView { data in
            self.configuration = .init(
                apiKey: data.apiKey,
                proxyURL: data.proxy.nonEmpty,
                useStoreKit2: data.storeKit2Enabled,
                observerMode: data.observerMode,
                entitlementVerificationMode: data.verificationMode
            )
        }
    }

    private var isConfigured: Bool {
        return self.configuration != nil
    }

}
