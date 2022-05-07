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
        .configurationBuilder(withAPIKey: "")
        .with(apiKey: "")
        .with(appUserID: "")
        .with(observerMode: false)
        .with(userDefaults: UserDefaults.standard)
        .with(dangerousSettings: DangerousSettings())
        .with(networkTimeoutSeconds: 1)
        .with(storeKit1TimeoutSeconds: 1)
        .with(usesStoreKit2IfAvailable: false)
        .build()
    print(configuration)
}
