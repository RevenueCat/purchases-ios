//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMSession.swift
//
//  Created by RevenueCat.

import Foundation

/// Holds the tokens returned by the IAM authentication service.
struct IAMSession: Equatable, Codable {

    let accessToken: String?
    let refreshToken: String?
    let idToken: String?
    /// Whether the session was established via anonymous login.
    let isAnonymous: Bool
    /// The subject claim from the verified ID token.
    /// Populated after JWT verification completes and persisted to Keychain
    /// so it is available immediately on subsequent launches.
    let subject: String?

    init(accessToken: String?,
         refreshToken: String?,
         idToken: String?,
         isAnonymous: Bool,
         subject: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.isAnonymous = isAnonymous
        self.subject = subject
    }

}
