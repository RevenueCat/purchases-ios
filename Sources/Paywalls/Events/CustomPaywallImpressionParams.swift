//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomPaywallImpressionParams.swift
//
//  Created by Rick van der Linden.

import Foundation

/// Parameters for tracking a custom paywall impression.
struct CustomPaywallImpressionParams {

    /// An optional identifier for the custom paywall being shown.
    let paywallId: String?

    init(paywallId: String? = nil) {
        self.paywallId = paywallId
    }

}

extension CustomPaywallImpressionParams: Sendable {}
