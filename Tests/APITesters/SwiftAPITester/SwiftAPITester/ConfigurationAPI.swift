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
        .with(appUserID: "")
        .with(appUserID: nil)
        .with(observerMode: true, storeKitVersion: .storeKit2)
        .with(userDefaults: UserDefaults.standard)
        .with(dangerousSettings: DangerousSettings())
        .with(dangerousSettings: DangerousSettings(autoSyncPurchases: true))
        .with(networkTimeout: 1)
        .with(storeKit1Timeout: 1)
        .with(platformInfo: Purchases.PlatformInfo(flavor: "", version: ""))
        .with(storeKitVersion: .default)
        .with(entitlementVerificationMode: .informational)

    let _: Configuration = builder.build()
}

@available(*, deprecated)
func checkDeprecatedConfiguration(_ builder: Configuration.Builder) {
    _ = builder
        .with(usesStoreKit2IfAvailable: false)
}
