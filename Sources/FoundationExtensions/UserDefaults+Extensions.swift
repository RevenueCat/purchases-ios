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

    // swiftlint:disable force_unwrapping

    // These are the only 2 documented reasons why `.init(suiteName:)` might return `nil`:
    // - "Because a suite manages the defaults of a specified app group, a suite name
    // must be distinct from your app’s main bundle identifier.
    // - The globalDomain is also an invalid suite name, because it isn't writeable by apps.
    //
    // Because we know at compile time that it's neither of those, this is a safe force-unwrap.
    static let revenueCatSuite: UserDefaults = .init(suiteName: UserDefaults.revenueCatSuiteName)!

    // swiftlint:enable force_unwrapping

    private static let revenueCatSuiteName = "com.revenuecat.user_defaults"

}

extension UserDefaults {

    /// Determines the "default" `UserDefaults` to use for the SDK.
    ///
    /// Moving foward, this default is `UserDefaults.revenueCatSuite`,
    /// but existing users will continue using `UserDefaults.standard` for compatibility.
    /// This is determined by the presence of an app user ID in `UserDefaults.standard`.
    static func computeDefault() -> UserDefaults {
        let standard: UserDefaults = .standard

        if standard.value(forKey: DeviceCache.CacheKeys.appUserDefaults.rawValue) != nil {
            Logger.debug(Strings.configure.using_user_defaults_standard)
            return standard
        } else {
            Logger.debug(Strings.configure.using_user_defaults_suite_name)
            return .revenueCatSuite
        }
    }

}
