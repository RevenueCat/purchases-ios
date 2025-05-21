//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBillingHTTPRequestPath.swift
//
//  Created by Toni Rico on 5/6/25.

import Foundation

extension HTTPRequest.WebBillingPath: HTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://api.revenuecat.com")!

    var authenticated: Bool {
        switch self {
        case .getWebProducts:
            return true
        }
    }

    var shouldSendEtag: Bool {
        switch self {
        case .getWebProducts:
            return true
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
        case let .getWebProducts(appUserID):
            return "/rcbilling/v1/subscribers/\(appUserID.trimmedAndEscaped)/offering_products"
        }
    }

    var name: String {
        switch self {
        case .getWebProducts:
            return "get_web_products"
        }
    }

}
