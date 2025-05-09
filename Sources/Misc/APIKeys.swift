//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  APIKeys.swift
//
//  Created by Antonio Pallares on 7/5/25.

import Foundation

// swiftlint:disable nesting

extension Purchases {

    /// Holds the API keys used to initialize the SDK.
    internal struct APIKeys {

        internal enum Store {
            case appStore
            case webBilling
        }

        /// The App Store API key.
        let apiKey: String

        /// The Web Billing API key.
        let webBillingAPIKey: String?
    }

}

extension Purchases.APIKeys.Store {

    func getAPIKey(from apiKeys: Purchases.APIKeys) -> String? {
        switch self {
        case .appStore:
            return apiKeys.apiKey
        case .webBilling:
            return apiKeys.webBillingAPIKey
        }
    }

    var description: String {
        switch self {
        case .appStore:
            return "App Store"
        case .webBilling:
            return "Web Billing"
        }
    }
}

extension Purchases.APIKeys: CustomDebugStringConvertible {

    var debugDescription: String {
        return """
        APIKeys(
            apiKey: '\(apiKey)',
            webBillingAPIKey: '\(webBillingAPIKey ?? "<nil>")'
        """
    }
}
