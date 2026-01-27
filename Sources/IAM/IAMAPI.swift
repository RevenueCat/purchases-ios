//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMAPI.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

/// API for IAM (Identity and Access Management) authentication operations
class IAMAPI {

    private let anonymousLoginCallbacksCache: CallbackCache<AnonymousLoginCallback>
    private let refreshTokenCallbacksCache: CallbackCache<RefreshTokenCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.anonymousLoginCallbacksCache = CallbackCache<AnonymousLoginCallback>()
        self.refreshTokenCallbacksCache = CallbackCache<RefreshTokenCallback>()
    }

    /// Perform anonymous login to obtain IAM tokens and app_user_id
    /// - Parameters:
    ///   - reference: Optional unique identifier for the anonymous user
    ///   - completion: Completion handler with tokens and app_user_id, or error
    func performAnonymousLogin(
        reference: String? = nil,
        completion: @escaping AnonymousLoginResponseHandler
    ) {
        // Use a placeholder appUserID for the request configuration
        // The actual appUserID will be returned from the backend
        let config = NetworkOperation.UserSpecificConfiguration(
            httpClient: self.backendConfig.httpClient,
            appUserID: "" // Placeholder for IAM login
        )

        let factory = AnonymousLoginOperation.createFactory(
            configuration: config,
            reference: reference,
            anonymousLoginCallbackCache: self.anonymousLoginCallbacksCache
        )

        let callback = AnonymousLoginCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.anonymousLoginCallbacksCache.add(callback)

        self.backendConfig.operationQueue.addCacheableOperation(
            with: factory,
            cacheStatus: cacheStatus
        )
    }

    /// Refresh IAM tokens using a refresh token
    /// - Parameters:
    ///   - refreshToken: The refresh token to use
    ///   - completion: Completion handler with new tokens, or error
    func refreshTokens(
        refreshToken: String,
        completion: @escaping RefreshTokenResponseHandler
    ) {
        // Use a placeholder appUserID for the request configuration
        let config = NetworkOperation.UserSpecificConfiguration(
            httpClient: self.backendConfig.httpClient,
            appUserID: "" // Placeholder for token refresh
        )

        let factory = RefreshTokenOperation.createFactory(
            configuration: config,
            refreshToken: refreshToken,
            refreshTokenCallbackCache: self.refreshTokenCallbacksCache
        )

        let callback = RefreshTokenCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.refreshTokenCallbacksCache.add(callback)

        self.backendConfig.operationQueue.addCacheableOperation(
            with: factory,
            cacheStatus: cacheStatus
        )
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension IAMAPI: @unchecked Sendable {}
