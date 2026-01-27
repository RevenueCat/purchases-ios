//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMError.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

/// Errors that can occur during IAM authentication operations
enum IAMError: Error {

    /// Authentication failed with an underlying error
    case authenticationFailed(Error)

    /// Token refresh failed with an underlying error
    case tokenRefreshFailed(Error)

    /// The stored tokens are invalid or corrupted
    case invalidTokens

    /// A network error occurred during authentication
    case networkError(Error)

    /// IAM authentication is not enabled in SDK configuration
    case iamNotEnabled

    /// Failed to store tokens in secure storage
    case tokenStorageFailed(Error)

    /// Failed to load tokens from secure storage
    case tokenLoadFailed(Error)

    /// No refresh token available for token refresh operation
    case noRefreshToken

    /// The backend response was missing the app_user_id
    case missingAppUserID

}

extension IAMError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let error):
            return "IAM authentication failed: \(error.localizedDescription)"
        case .tokenRefreshFailed(let error):
            return "IAM token refresh failed: \(error.localizedDescription)"
        case .invalidTokens:
            return "IAM tokens are invalid or corrupted"
        case .networkError(let error):
            return "IAM network error: \(error.localizedDescription)"
        case .iamNotEnabled:
            return "IAM authentication is not enabled. Configure SDK with iamAuthenticationEnabled = true"
        case .tokenStorageFailed(let error):
            return "Failed to store IAM tokens: \(error.localizedDescription)"
        case .tokenLoadFailed(let error):
            return "Failed to load IAM tokens: \(error.localizedDescription)"
        case .noRefreshToken:
            return "No refresh token available for token refresh"
        case .missingAppUserID:
            return "Backend response is missing app_user_id"
        }
    }

}
