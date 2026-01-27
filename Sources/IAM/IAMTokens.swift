//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMTokens.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

/// Represents the authentication tokens returned by the IAM authentication endpoints.
struct IAMTokens: Codable, Sendable {

    /// The ID token (JWT) containing user identity claims
    let idToken: String

    /// The access token used for authorizing API requests
    let accessToken: String

    /// The refresh token used to obtain new access tokens
    let refreshToken: String

    /// Optional expiration time in seconds
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }

}

extension IAMTokens {

    /// Returns true if all tokens are present and non-empty
    var isValid: Bool {
        return !idToken.isEmpty && !accessToken.isEmpty && !refreshToken.isEmpty
    }

}
