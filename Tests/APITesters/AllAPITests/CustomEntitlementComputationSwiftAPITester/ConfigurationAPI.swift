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
        .builder(withAPIKey: "", appUserID: "")
        .with(apiKey: "")
        .with(introEligibilityWarmupPriority: .utility)
        .build()

    print(configuration)
}
