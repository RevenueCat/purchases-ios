//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesConfiguredNotifier.swift
//

import Foundation

/// RevenueCatUI implements this so ``Purchases`` can invoke it without importing that module.
@_spi(Internal)
@objc public protocol PurchasesPostConfigurationStep: NSObjectProtocol {

    /// Called after ``Purchases/shared`` has been set by ``Purchases/configure(withAPIKey:)``.
    static func purchasesDidConfigure()

}

/// Sends a message to listeners when ``Purchases`` is configured.
enum PurchasesConfiguredNotifier {

    // OBJC symbols must be linked for them to receive the notification
    static let serviceClassNames = ["RCPurchasesUIService"]

    static func notify() {
        for name in serviceClassNames {
            guard let service = NSClassFromString(name) as? PurchasesPostConfigurationStep.Type else {
                return
            }

            service.purchasesDidConfigure()
        }
    }

}
