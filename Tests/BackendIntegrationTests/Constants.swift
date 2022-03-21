//
//  Constants.swift
//  BackendIntegrationTests
//
//  Created by Andrés Boedo on 5/4/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

enum Constants {
    static let apiKey = "REVENUECAT_API_KEY"
    // Server URL for the tests. If set to empty string, we'll use the default URL.
    static let proxyURL = "REVENUECAT_PROXY_URL"

    static let userDefaultsSuiteName = "BackendIntegrationTests"
    static let storeKitConfigFileName = "RevenueCat_IntegrationPurchaseTesterConfiguration"
}
