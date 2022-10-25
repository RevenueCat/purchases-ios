//
//  PurchaseTesterApp.swift
//  Shared
//
//  Created by Josh Holtz on 1/10/22.
//

import SwiftUI

import RevenueCat

@main
struct PurchaseTesterApp: App {

    @State
    private var configuration: ConfiguredPurchases?
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                if let configuration {
                    ContentView(configuration: configuration)
                } else {
                    ConfigurationView { data in
                        self.configuration = .init(
                            apiKey: data.apiKey,
                            proxyURL: data.proxy.nonEmpty,
                            useStoreKit2: data.storeKit2Enabled
                        )
                    }
                }
            }
        }
    }

}
