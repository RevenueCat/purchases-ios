//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMKeychainStorage.swift
//
//  Created by RevenueCat.

import Foundation
import Security

/// Persists an ``IAMSession`` to the iOS/macOS Keychain so that authentication
/// tokens survive app restarts without requiring the user to re-authenticate.
///
/// Each RevenueCat API key gets its own Keychain entry so that multiple apps (or
/// multiple project configurations within one app) never share session state.
final class IAMKeychainStorage: @unchecked Sendable {

    private let service = "com.revenuecat.purchases.iam-session"
    private let account: String

    init(apiKey: String) {
        self.account = apiKey
    }

    func save(_ session: IAMSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func load() -> IAMSession? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }

        return try? JSONDecoder().decode(IAMSession.self, from: data)
    }

    func clear() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }

}
