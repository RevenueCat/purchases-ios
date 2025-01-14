//
//  SubscriptionInfo+Localized.swift
//  RevenueCat
//
//  Created by Facundo Menzella on 14/1/25.
//

import RevenueCat

extension SubscriptionInfo {

    var localizedStore: String {
        switch store {
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
