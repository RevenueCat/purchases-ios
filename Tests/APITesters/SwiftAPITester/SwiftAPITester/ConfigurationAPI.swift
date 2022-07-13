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
        .with(observerMode: false)
        .with(userDefaults: UserDefaults.standard)
        .with(dangerousSettings: DangerousSettings())
        .with(networkTimeout: 1)
        .with(storeKit1Timeout: 1)
        .with(usesStoreKit2IfAvailable: false)
        .with(platformInfo: Purchases.PlatformInfo(flavor: "", version: ""))
        .build()
    print(configuration)
}
