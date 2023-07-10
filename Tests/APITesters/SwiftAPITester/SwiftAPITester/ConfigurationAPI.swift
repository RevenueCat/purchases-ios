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
        .with(observerMode: false)
        .with(userDefaults: UserDefaults.standard)
        .with(dangerousSettings: DangerousSettings())
        .with(dangerousSettings: DangerousSettings(autoSyncPurchases: true))
        .with(networkTimeout: 1)
        .with(storeKit1Timeout: 1)
        .with(platformInfo: Purchases.PlatformInfo(flavor: "", version: ""))

    let _: Configuration = builder.build()

    if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
        let _: Configuration = builder
            .with(entitlementVerificationMode: .informational)
            .build()
    }
}
