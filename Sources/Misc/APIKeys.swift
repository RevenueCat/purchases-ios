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

extension Purchases {

    /// Holds the API keys used to initialize the SDK.
    internal struct APIKeys {
        /// The App Store API key.
        let apiKey: String

        /// The Web Billing API key.
        let webBillingAPIKey: String?
    }

}
