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
    static let loadShedderApiKey = "REVENUECAT_LOAD_SHEDDER_API_KEY"
    static let customEntitlementComputationApiKey = "REVENUECAT_CUSTOM_ENTITLEMENT_COMPUTATION_API_KEY"
    
    // The API Base URL for the tests. Configures the main backend in the SDK while still using the fallback backend logic as opposed to the proxyURL
    static let apiBaseURL = "REVENUECAT_API_BASE_URL"

    // Server URL for the tests. If set to empty string, we'll use the default URL.
    static let proxyURL = "REVENUECAT_PROXY_URL"

    static let userDefaultsSuiteName = "BackendIntegrationTests"
    static let storeKitConfigFileName = "RevenueCat_IntegrationPurchaseTesterConfiguration"

}
