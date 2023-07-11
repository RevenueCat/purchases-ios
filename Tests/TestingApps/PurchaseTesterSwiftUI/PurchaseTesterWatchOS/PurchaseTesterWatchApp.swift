//
//  PurchaseTesterWatchApp.swift
//  PurchaseTesterWatchOS Watch App
//
//  Created by Nacho Soto on 12/12/22.
//

import SwiftUI

import Core

@main
struct PurchaseTesterWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                configuration: .init(apiKey: Constants.apiKey,
                                     proxyURL: nil,
                                     useStoreKit2: true,
                                     observerMode: false,
                                     entitlementVerificationMode: .informational)
            )
        }
    }
}
