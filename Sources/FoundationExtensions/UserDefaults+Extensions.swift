//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UserDefaults+Extensions.swift
//
//  Created by Nacho Soto on 11/9/22.

import Foundation

extension UserDefaults {

    #if DEBUG
    /// The "default" `UserDefaults` to use for the SDK.
    ///
    /// Moving foward, this default is `UserDefaults.revenueCatSuite`,
    /// but existing users will continue using `UserDefaults.standard` for compatibility.
    /// This is determined by the presence of an app user ID in `UserDefaults.standard`.
    ///
    /// Computed property only in `DEBUG` to be able to test it under different conditions.
    /// In release mode, it gets cached.
    static var `default`: UserDefaults { .computeDefault() }
    #else
    static let `default`: UserDefaults = .computeDefault()
    #endif

    // These are the only 2 documented reasons why `.init(suiteName:)` might return `nil`:
    // - "Because a suite manages the defaults of a specified app group, a suite name
    // must be distinct from your app’s main bundle identifier.
    // - The globalDomain is also an invalid suite name, because it isn't writeable by apps.
    //
    // Because we know at compile time that it's neither of those, this is a safe force-unwrap.
    static let revenueCatSuite: UserDefaults = .init(suiteName: UserDefaults.revenueCatSuiteName)!

}

private extension UserDefaults {

    static let revenueCatSuiteName = "com.revenuecat.user_defaults"

    static func computeDefault() -> UserDefaults {
        let standard: UserDefaults = .standard

        if standard.value(forKey: DeviceCache.CacheKeys.appUserDefaults.rawValue) != nil {
            return standard
        } else {
            return .revenueCatSuite
        }
    }

}
