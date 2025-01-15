//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Store+Localized.swift
//
//
//  Created by Facundo Menzella on 14/1/25.
//
import RevenueCat

extension Store {

    var localizedName: String {
        switch self {
        case .appStore: return "Apple App Store"
        case .macAppStore: return "Mac App Store"
        case .playStore: return "Google Play Store"
        case .stripe: return "Stripe"
        case .promotional: return "Promotional"
        case .amazon: return "Amazon Store"
        case .rcBilling: return "Web"
        case .external: return "External Purchases"
        case .unknownStore: return "Unknown Store"
        }
    }
}
