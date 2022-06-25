//
//  Package+Extensions.swift
//  PurchaseTester (iOS)
//
//  Created by Josh Holtz on 6/22/22.
//

import RevenueCat

extension Package {
    var display: String {
        switch self.packageType {
        case .unknown:
            return "unknown"
        case .custom:
            return "custom"
        case .lifetime:
            return "lifetime"
        case .annual:
            return "annual"
        case .sixMonth:
            return "six month"
        case .threeMonth:
            return "three month"
        case .twoMonth:
            return "two month"
        case .monthly:
            return "monthly"
        case .weekly:
            return "weekly"
        @unknown default:
            fatalError()
        }
    }
}
