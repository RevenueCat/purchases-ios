//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IDTokenClaims.swift
//
//  Created by RevenueCat.

import Foundation

/// The verified claims extracted from the IAM ID token (JWT).
///
/// Available via ``Purchases/idTokenClaims`` after a successful IAM login.
/// The token's signature is verified against the project's public keys before
/// these claims are exposed.
public struct IDTokenClaims {

    /// The subject identifier — the authenticated user's unique ID within this project.
    public let subject: String

    /// The issuer of the token, identifying the RevenueCat project.
    public let issuer: String

    /// The audience the token is intended for.
    public let audience: [String]

    /// When the token was issued.
    public let issuedAt: Date

    /// When the token expires.
    public let expiration: Date

    /// All raw claims from the token payload, keyed by claim name.
    ///
    /// Use this to access any custom or additional claims not surfaced as typed properties.
    public let rawClaims: [String: Any]

}
