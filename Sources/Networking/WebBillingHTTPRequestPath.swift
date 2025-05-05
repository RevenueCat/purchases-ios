//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsHTTPRequestPath.swift
//
//  Created by Cesar de la Vega on 8/4/24.

import Foundation

extension HTTPRequest.WebBillingPath: HTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://api-diagnostics.revenuecat.com")!

    var authenticated: Bool {
        switch self {
        case .getWebProducts:
            return true
        }
    }

    var shouldSendEtag: Bool {
        switch self {
        case .getWebProducts:
            return false
        }
    }

    var supportsSignatureVerification: Bool {
        switch self {
        case .getWebProducts:
            return false
        }
    }

    var needsNonceForSigning: Bool {
        switch self {
        case .getWebProducts:
            return false
        }
    }

    var relativePath: String {
        switch self {
        case let .getWebProducts(appUserId, productIds):
            return "subscribers/\(appUserId.trimmedAndEscaped))/products?id=\(productIds.joined(separator: "&id="))"
        }
    }

    var name: String {
        switch self {
        case .getWebProducts:
            return "get_web_products"
        }
    }

}
