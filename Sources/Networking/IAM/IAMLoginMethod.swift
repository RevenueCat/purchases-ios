//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMLoginMethod.swift
//
//  Created by RevenueCat.

import Foundation

/// Represents the authentication method to use when establishing an IAM session.
///
/// Use the static factory methods to create instances:
/// - ``anonymous(reference:)``
/// - ``oidc(idToken:)``
/// - ``google(idToken:)``
/// - ``apple(idToken:)``
public struct IAMLoginMethod {

    internal enum MethodType {

        case anonymous(reference: String?)
        case oidc(idToken: String)
        case google(idToken: String)
        case apple(idToken: String)

    }

    internal let methodType: MethodType

    private init(_ methodType: MethodType) {
        self.methodType = methodType
    }

    /// Authenticates anonymously with an optional reference identifier.
    ///
    /// - Parameter reference: An optional unique identifier to associate with the anonymous session.
    public static func anonymous(reference: String? = nil) -> IAMLoginMethod {
        .init(.anonymous(reference: reference))
    }

    /// Authenticates using an OIDC ID token.
    ///
    /// - Parameter idToken: An ID token for OIDC authentication.
    public static func oidc(idToken: String) -> IAMLoginMethod {
        .init(.oidc(idToken: idToken))
    }

    /// Authenticates using a Google Sign-In ID token.
    ///
    /// - Parameter idToken: An ID token obtained from Google Sign-In.
    public static func google(idToken: String) -> IAMLoginMethod {
        .init(.google(idToken: idToken))
    }

    /// Authenticates using an Apple Sign-In ID token.
    ///
    /// - Parameter idToken: An ID token obtained from Sign in with Apple.
    public static func apple(idToken: String) -> IAMLoginMethod {
        .init(.apple(idToken: idToken))
    }

}
