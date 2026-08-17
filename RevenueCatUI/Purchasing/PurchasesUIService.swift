//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesUIService.swift
//

import Foundation
@_spi(Internal) import RevenueCat

/// Receives a message from `Purchases` after `Purchases.shared` is configured.
///
/// Looked up by ObjC name so RevenueCat does not need to import this module.
///
/// Reachable RevenueCatUI entry points call ``activateIfNeeded()`` so this class is
/// retained by a real, observable use of runtime state. Linking happens before
/// execution, so that call can run after ``Purchases/configure`` and still keep
/// the class in the binary. The same path replays if RevenueCatUI loads after
/// configuration.
@objc(RCPurchasesUIService)
final class PurchasesUIService: NSObject, PurchasesPostConfigurationStep {

    private static let lock = NSLock()
    private static var didConfigure = false

    /// Retains this class from a public RevenueCatUI entry point.
    ///
    /// Reads runtime state and may mutate locked state, so it cannot be
    /// optimized away as a no-op keep-alive.
    static func activateIfNeeded() {
        Self.purchasesDidConfigure()
    }

    /// Cheap wake-up. Must stay cheap: start subsciptions here later, do not perform heavy work synchronously here.
    @objc static func purchasesDidConfigure() {
        lock.withLock {
            guard !didConfigure else { return }
            self.didConfigure = true
            Logger.debug(Strings.purchases_did_configure)
            // Next PR: subscribe to publishers
        }
    }

    #if DEBUG
    static func resetForTests() {
        lock.withLock {
            Self.didConfigure = false
        }
    }
    #endif

}
