//
//  ConfigurationAPI.swift
//  SwiftAPITester
//
//  Created by Joshua Liebowitz on 5/6/22.
//

import Foundation
import RevenueCat

func checkConfigurationAPI() {
    let configuration = Configuration
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
        // Trusted Entitlements: internal until ready to be made public.
        // .with(entitlementVerificationMode: .informational)
        .build()

    #if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
    _ = DangerousSettings(autoSyncPurchases: false,
                          customEntitlementComputation: true)
    #endif

    print(configuration)
}
