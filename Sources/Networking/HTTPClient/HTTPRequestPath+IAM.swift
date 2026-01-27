//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequestPath+IAM.swift
//
//  Created by RevenueCat on 1/27/26.

import Foundation

// MARK: - IAM Paths

extension HTTPRequest {

    enum IAMPath: Hashable {

        case login
        case token

    }

}

extension HTTPRequest.IAMPath: HTTPRequestPath {

    static var serverHostURL: URL {
        // IAM endpoints use /auth base path
        // swiftlint:disable:next force_unwrapping
        return URL(string: "https://api.revenuecat.com/auth")!
    }

    var authenticated: Bool {
        // IAM endpoints use API key for authentication (not IAM tokens)
        return true
    }

    var shouldSendEtag: Bool {
        // IAM endpoints don't support ETag caching
        return false
    }

    var supportsSignatureVerification: Bool {
        // IAM endpoints support signature verification
        return true
    }

    var needsNonceForSigning: Bool {
        // IAM endpoints need nonce for signing
        return true
    }

    var relativePath: String {
        switch self {
        case .login:
            return "/login"
        case .token:
            return "/token"
        }
    }

    var name: String {
        switch self {
        case .login:
            return "iam_login"
        case .token:
            return "iam_token"
        }
    }

}
