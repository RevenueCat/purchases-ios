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
//

import Foundation

/// Persists the identifier for RevenueCat's isolated website data store.
@_spi(Internal) public enum WebViewDataStoreIdentifierStore {

    private static let key = "com.revenuecat.webViewDataStoreIdentifier"
    private static let lock = Lock()

    private static let defaults = UserDefaults.revenueCatSuite

    /// Returns the stable identifier used by RevenueCat web views.
    public static func identifier() -> UUID {
        return self.identifier(in: Self.defaults)
    }

    static func identifier(in userDefaults: UserDefaults) -> UUID {
        return Self.lock.perform {
            if let value = userDefaults.string(forKey: Self.key),
               let identifier = UUID(uuidString: value) {
                return identifier
            }

            let identifier = UUID()
            userDefaults.set(identifier.uuidString, forKey: Self.key)
            return identifier
        }
    }

    static func clearIdentifier(in userDefaults: UserDefaults) -> UUID? {
        return Self.lock.perform {
            defer { userDefaults.removeObject(forKey: Self.key) }

            return userDefaults.string(forKey: Self.key)
                .flatMap(UUID.init(uuidString:))
        }
    }

}
