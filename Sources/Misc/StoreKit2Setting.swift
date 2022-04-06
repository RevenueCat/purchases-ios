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

    /// Use SK2 if available for certain APIs that provide a better implementation
    case enabledOnlyForOptimizations

    /// Enable SK2 in all APIs if available
    case enabledIfAvailable

}

extension StoreKit2Setting {

    init(useStoreKit2IfAvailable: Bool) {
        self = useStoreKit2IfAvailable
            ? .enabledIfAvailable
            : .enabledOnlyForOptimizations
    }

    static let `default`: Self = .enabledOnlyForOptimizations

}
