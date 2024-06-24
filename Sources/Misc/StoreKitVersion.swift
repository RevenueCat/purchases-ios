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

    /// Always use StoreKit 1.
    @objc(RCStoreKitVersion1)
    case storeKit1 = 1

    /// Always use StoreKit 2 (StoreKit 1 will be used if StoreKit 2 is not available in the current device.)
    ///
    /// - Warning: Make sure you have an In-App Purchase Key configured in your app.
    /// Please see https://rev.cat/in-app-purchase-key-configuration for more info.
    @objc(RCStoreKitVersion2)
    case storeKit2 = 2

}

public extension StoreKitVersion {

    /// Let RevenueCat use the most appropiate version of StoreKit
    static let `default` = Self.storeKit2

}

extension StoreKitVersion: CustomDebugStringConvertible {

    /// Returns a spurtring representation of the StoreKit version
    public var debugDescription: String {
        switch self {
        case .storeKit1: return "1"
        case .storeKit2: return "2"
        }
    }
}

extension StoreKitVersion {

    /// - Returns: `true` if SK2 is available in this device.
    static var isStoreKit2Available: Bool {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return true
        } else {
            return false
        }
    }

    /// - Returns: `true` if and only if SK2 is enabled and it's available.
    var isStoreKit2EnabledAndAvailable: Bool {
        switch self {
        case .storeKit1: return false
        case .storeKit2: return Self.isStoreKit2Available
        }
    }

    /// Returns the effective version of StoreKit used.
    /// This can be different from the configured version if StoreKit 2 is not available on the current device.
    var effectiveVersion: StoreKitVersion {
        switch self {
        case .storeKit1:
            return .storeKit1
        case .storeKit2:
            if Self.isStoreKit2Available {
                return .storeKit2
            } else {
                return .storeKit1
            }
        }
    }

}
