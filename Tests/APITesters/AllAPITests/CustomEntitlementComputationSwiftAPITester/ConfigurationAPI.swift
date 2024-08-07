//
//  ConfigurationAPI.swift
//  SwiftAPITester
//
//  Created by Joshua Liebowitz on 5/6/22.
//

import Foundation
import RevenueCat_CustomEntitlementComputation

func checkConfigurationAPI() {
    let configuration = Configuration
        .builder(withAPIKey: "")
        .with(apiKey: "")
        .with(appUserID: nil)
        .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit1)
        .with(userDefaults: UserDefaults.standard)
        .with(dangerousSettings: DangerousSettings())
        .with(dangerousSettings: DangerousSettings(autoSyncPurchases: true))
        .with(networkTimeout: 1)
        .with(storeKit1Timeout: 1)
        .with(platformInfo: Purchases.PlatformInfo(flavor: "", version: ""))
        // .with(entitlementVerificationMode: .informational)
        .build()

    print(configuration)
}

@available(*, deprecated)
func checkDeprecatedConfiguration(_ builder: Configuration.Builder) {
    _ = builder
        .with(usesStoreKit2IfAvailable: true)
        .with(appUserID: "")
}
