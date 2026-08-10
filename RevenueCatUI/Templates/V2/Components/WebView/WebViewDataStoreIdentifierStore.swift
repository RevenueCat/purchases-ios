//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebViewDataStoreIdentifierStore.swift
//
//  Created by Jacob Zivan Rakidzich on 8/10/26.

import Foundation

enum WebViewDataStoreIdentifierStore {

    private static let key = "com.revenuecat.webViewDataStoreIdentifier"

    static let defaults: UserDefaults = {
        let defaults = UserDefaults(suiteName: "com.revenuecat.webViewData")
        assert(defaults != nil)
        return defaults ?? .standard
    }()

    static func identifier(in userDefaults: UserDefaults = Self.defaults) -> UUID {
        if let value = userDefaults.string(forKey: Self.key),
           let identifier = UUID(uuidString: value) {
            return identifier
        }

        let identifier = UUID()
        userDefaults.set(identifier.uuidString, forKey: Self.key)
        return identifier
    }

    static func clearIdentifier(in userDefaults: UserDefaults = Self.defaults) -> UUID? {
        defer { userDefaults.removeObject(forKey: Self.key) }

        return userDefaults.string(forKey: Self.key)
            .flatMap(UUID.init(uuidString:))
    }

}
