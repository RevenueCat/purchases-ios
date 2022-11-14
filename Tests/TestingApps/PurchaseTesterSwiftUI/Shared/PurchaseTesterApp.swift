//
//  PurchaseTesterApp.swift
//  Shared
//
//  Created by Josh Holtz on 1/10/22.
//

import Foundation
import SwiftUI

import RevenueCat

@main
struct PurchaseTesterApp: App {

    @State
    private var configuration: ConfiguredPurchases?
    
    var body: some Scene {
        WindowGroup(id: Windows.default.rawValue) {
            NavigationView {
                if let configuration {
                    ContentView(configuration: configuration)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    self.configuration = nil
                                } label: {
                                    Text("Reconfigure")
                                }
                            }
                        }
                } else {
                    ConfigurationView { data in
                        self.configuration = .init(
                            apiKey: data.apiKey,
                            proxyURL: data.proxy.nonEmpty,
                            useStoreKit2: data.storeKit2Enabled,
                            observerMode: data.observerMode
                        )
                    }
                }
            }
            .navigationViewStyle(.stack)
            .animation(.default, value: self.isConfigured)
            .transition(.opacity)
        }

        WindowGroup(id: Windows.logs.rawValue) {
            LoggerView(logger: ConfiguredPurchases.logger)
        }
    }

    private var isConfigured: Bool {
        return self.configuration != nil
    }

}
