//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2Setting.swift
//
//  Created by Nacho Soto on 4/6/22.

/// Defines when StoreKit 2 APIs may be used
enum StoreKit2Setting {

    /// Never use SK2
    case disabled

    /// Use SK2 (if available in the current device) only for certain APIs that provide a better implementation
    /// For example: intro eligibility, determining if a receipt has purchases, managing subscriptions.
    case enabledOnlyForOptimizations

    /// Enable SK2 in all APIs if available in the current device
    case enabledForCompatibleDevices

}

extension StoreKit2Setting {

    init(useStoreKit2IfAvailable: Bool) {
        self = useStoreKit2IfAvailable
            ? .enabledForCompatibleDevices
            : .enabledOnlyForOptimizations
    }

    static let `default`: Self = .enabledOnlyForOptimizations

}

extension StoreKit2Setting {

    /// - Returns: `true` if SK2 is available in this device.
    static var isStoreKit2Available: Bool {
        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            return true
        } else {
            return false
        }
    }

    /// Returns: `true` if SK2 is enabled.
    var usesStoreKit2IfAvailable: Bool {
        switch self {
        case .disabled: return false
        case .enabledOnlyForOptimizations: return false
        case .enabledForCompatibleDevices: return true
        }
    }

    /// - Returns: `true` if and only if SK2 is enabled and it's available.
    var shouldOnlyUseStoreKit2: Bool {
        return self.isEnabledAndAvailable
    }

    /// - Returns: `true` if and only if SK2 is enabled and it's available.
    var isEnabledAndAvailable: Bool {
        switch self {
        case .disabled, .enabledOnlyForOptimizations: return false
        case .enabledForCompatibleDevices: return Self.isStoreKit2Available
        }
    }

}

extension StoreKit2Setting: CustomDebugStringConvertible {

    var debugDescription: String {
        switch self {
        case .disabled: return "disabled"
        case .enabledOnlyForOptimizations: return "optimizations-only"
        case .enabledForCompatibleDevices: return "enabled"
        }
    }

}
