//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMManager.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

/// Core IAM authentication manager that orchestrates token lifecycle
class IAMManager {

    private let tokenStore: IAMTokenStore
    private let iamAPI: IAMAPI
    private let deviceCache: DeviceCache
    private let currentTokens: Atomic<IAMTokens?>
    private let isRefreshing: Atomic<Bool>

    init(tokenStore: IAMTokenStore, iamAPI: IAMAPI, deviceCache: DeviceCache) {
        self.tokenStore = tokenStore
        self.iamAPI = iamAPI
        self.deviceCache = deviceCache
        self.currentTokens = .init(tokenStore.loadTokens())
        self.isRefreshing = .init(false)
    }

    /// The current access token, if available
    var currentAccessToken: String? {
        return self.currentTokens.value?.accessToken
    }

    /// Whether valid tokens are currently stored
    var hasValidTokens: Bool {
        guard let tokens = self.currentTokens.value else {
            return false
        }
        return tokens.isValid
    }

    /// Perform anonymous login to obtain IAM tokens and app_user_id
    /// - Parameters:
    ///   - reference: Optional unique identifier for the anonymous user
    ///   - completion: Completion handler with app_user_id or error
    func performAnonymousLogin(
        reference: String? = nil,
        completion: @escaping (Result<String, IAMError>) -> Void
    ) {
        Logger.info("IAM: Performing anonymous login")

        self.iamAPI.performAnonymousLogin(reference: reference) { result in
            switch result {
            case .success(let (tokens, appUserID)):
                // Store tokens
                do {
                    try self.tokenStore.store(tokens: tokens)
                    self.currentTokens.value = tokens

                    // Cache app_user_id
                    self.deviceCache.cache(appUserID: appUserID)

                    Logger.info("IAM: Anonymous login successful, app_user_id: \(appUserID)")
                    completion(.success(appUserID))
                } catch {
                    Logger.error("IAM: Failed to store tokens: \(error)")
                    completion(.failure(.tokenStorageFailed(error)))
                }

            case .failure(let error):
                Logger.error("IAM: Anonymous login failed: \(error)")
                completion(.failure(.authenticationFailed(error)))
            }
        }
    }

    /// Refresh IAM tokens using the stored refresh token
    /// - Parameter completion: Completion handler with success or error
    func refreshTokens(completion: @escaping (Result<Void, IAMError>) -> Void) {
        // Check if already refreshing to prevent concurrent refresh attempts
        guard !self.isRefreshing.value else {
            Logger.debug("IAM: Token refresh already in progress")
            completion(.failure(.tokenRefreshFailed(
                NSError(domain: "IAMManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Token refresh already in progress"
                ])
            )))
            return
        }

        // Get current refresh token
        guard let refreshToken = self.currentTokens.value?.refreshToken else {
            Logger.error("IAM: No refresh token available")
            completion(.failure(.noRefreshToken))
            return
        }

        Logger.info("IAM: Refreshing tokens")
        self.isRefreshing.value = true

        self.iamAPI.refreshTokens(refreshToken: refreshToken) { result in
            // Reset refreshing flag
            self.isRefreshing.value = false

            switch result {
            case .success(let newTokens):
                // Store new tokens
                do {
                    try self.tokenStore.store(tokens: newTokens)
                    self.currentTokens.value = newTokens

                    Logger.info("IAM: Token refresh successful")
                    completion(.success(()))
                } catch {
                    Logger.error("IAM: Failed to store refreshed tokens: \(error)")
                    completion(.failure(.tokenStorageFailed(error)))
                }

            case .failure(let error):
                Logger.error("IAM: Token refresh failed: \(error)")
                // Clear tokens on refresh failure (may be expired/invalid)
                self.clearTokens()
                completion(.failure(.tokenRefreshFailed(error)))
            }
        }
    }

    /// Clear all stored tokens
    func clearTokens() {
        Logger.info("IAM: Clearing tokens")
        self.tokenStore.clearTokens()
        self.currentTokens.value = nil
    }

}

extension IAMManager: @unchecked Sendable {}
