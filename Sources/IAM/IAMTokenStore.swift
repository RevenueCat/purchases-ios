//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMTokenStore.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation
import Security

/// Secure storage for IAM authentication tokens using iOS Keychain
class IAMTokenStore {

    private let service: String
    private let currentTokens: Atomic<IAMTokens?>

    private enum KeychainKey: String {
        case idToken = "com.revenuecat.iam.id_token"
        case accessToken = "com.revenuecat.iam.access_token"
        case refreshToken = "com.revenuecat.iam.refresh_token"
    }

    init(service: String = "com.revenuecat.iam") {
        self.service = service
        self.currentTokens = .init(nil)

        // Load tokens from keychain on initialization
        if let tokens = self.loadTokensFromKeychain() {
            self.currentTokens.value = tokens
        }
    }

    /// Store tokens securely in Keychain
    func store(tokens: IAMTokens) throws {
        // Store each token separately in keychain
        try storeInKeychain(key: .idToken, value: tokens.idToken)
        try storeInKeychain(key: .accessToken, value: tokens.accessToken)
        try storeInKeychain(key: .refreshToken, value: tokens.refreshToken)

        // Update in-memory cache
        self.currentTokens.value = tokens

        Logger.debug("IAM tokens stored successfully")
    }

    /// Load tokens from Keychain
    func loadTokens() -> IAMTokens? {
        return self.currentTokens.value
    }

    /// Clear all tokens from Keychain and memory
    func clearTokens() {
        deleteFromKeychain(key: .idToken)
        deleteFromKeychain(key: .accessToken)
        deleteFromKeychain(key: .refreshToken)

        self.currentTokens.value = nil

        Logger.debug("IAM tokens cleared")
    }

    // MARK: - Private Keychain Methods

    private func storeInKeychain(key: KeychainKey, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw IAMError.tokenStorageFailed(
                NSError(domain: "IAMTokenStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode token"])
            )
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw IAMError.tokenStorageFailed(
                NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [
                    NSLocalizedDescriptionKey: "Failed to store token in Keychain (status: \(status))"
                ])
            )
        }
    }

    private func loadFromKeychain(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func deleteFromKeychain(key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)
    }

    private func loadTokensFromKeychain() -> IAMTokens? {
        guard let idToken = loadFromKeychain(key: .idToken),
              let accessToken = loadFromKeychain(key: .accessToken),
              let refreshToken = loadFromKeychain(key: .refreshToken) else {
            return nil
        }

        return IAMTokens(
            idToken: idToken,
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: nil
        )
    }

}

extension IAMTokenStore: Sendable {}
