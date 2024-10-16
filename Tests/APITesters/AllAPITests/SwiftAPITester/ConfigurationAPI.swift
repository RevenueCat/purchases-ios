//
//  ConfigurationAPI.swift
//  SwiftAPITester
//
//  Created by Joshua Liebowitz on 5/6/22.
//

import Foundation
import RevenueCat

func checkConfigurationAPI() {
    let builder = Configuration
        .builder(withAPIKey: "")
        .with(apiKey: "")
        .with(appUserID: nil)
        .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
        .with(userDefaults: UserDefaults.standard)
        .with(dangerousSettings: DangerousSettings())
        .with(dangerousSettings: DangerousSettings(autoSyncPurchases: true))
        .with(networkTimeout: 1)
        .with(storeKit1Timeout: 1)
        .with(platformInfo: Purchases.PlatformInfo(flavor: "", version: ""))
        .with(storeKitVersion: .default)
        .with(entitlementVerificationMode: .informational)

    let _: Configuration = builder.build()

    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
        let _: Configuration = builder
            .with(entitlementVerificationMode: .informational)
            .build()
    }

    if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
        let _: Configuration = builder
            .with(diagnosticsEnabled: true)
            .build()
    }
}

@available(*, deprecated)
func checkDeprecatedConfiguration(_ builder: Configuration.Builder) {
    _ = builder
        .with(usesStoreKit2IfAvailable: false)
        .with(appUserID: "")
}
