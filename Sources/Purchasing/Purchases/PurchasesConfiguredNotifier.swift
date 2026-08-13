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
@objc public protocol PurchasesUIConfiguring: NSObjectProtocol {

    /// Called after ``Purchases/shared`` has been set by ``Purchases/configure(withAPIKey:)``.
    static func purchasesDidConfigure()

}

/// Sends a one-shot message to RevenueCatUI when ``Purchases`` is configured.
///
/// RevenueCat does not import RevenueCatUI. If the UI module is linked, its
/// `@objc(RCPurchasesUIService)` class is present and ``PurchasesUIConfiguring/purchasesDidConfigure()``
/// is invoked. Otherwise this is a no-op.
enum PurchasesConfiguredNotifier {

    /// Must match `@objc(RCPurchasesUIService)` in RevenueCatUI.
    static let uiServiceClassName = "RCPurchasesUIService"

    static func notify() {
        guard let service = NSClassFromString(Self.uiServiceClassName) as? PurchasesUIConfiguring.Type else {
            return
        }

        service.purchasesDidConfigure()
    }

}
