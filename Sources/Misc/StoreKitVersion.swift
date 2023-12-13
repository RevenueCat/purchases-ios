//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitVersion.swift
//
//  Created by Mark Villacampa on 4/13/23.

import Foundation

/// Defines which version of StoreKit may be used
@objc(RCStoreKitVersion)
public enum StoreKitVersion: Int {

    /// Always use StoreKit 1. StoreKit 2 will be used (if available in the current device) only for certain APIs
    /// that provide a better implementation. For example: intro eligibility, determining if a receipt has
    /// purchases, managing subscriptions.
    case storeKit1

    /// Always use StoreKit 2.
    case storeKit2

    /// Let RevenueCat use the most appropiate version of StoreKit
    case `default`
}

extension StoreKitVersion {

    /// - Returns: `true` if SK2 is available in this device.
    static var isStoreKit2Available: Bool {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            return true
        } else {
            return false
        }
    }

    /// - Returns: `true` if and only if SK2 is enabled and it's available.
    var isStoreKit2EnabledAndAvailable: Bool {
        switch self {
        case .storeKit1, .default: return false
        case .storeKit2: return Self.isStoreKit2Available
        }
    }

}

extension StoreKitVersion {

    var versionString: String {
        if self.isStoreKit2EnabledAndAvailable {
            return "2"
        } else {
            return "1"
        }
    }

}
