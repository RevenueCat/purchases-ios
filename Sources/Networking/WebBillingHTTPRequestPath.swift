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

    var usesAPISources: Bool {
        return true
    }

    var authenticated: Bool {
        switch self {
        case .getHostedCheckoutStatus:
            return true
        }
    }

    var shouldSendEtag: Bool {
        switch self {
        case .getHostedCheckoutStatus:
            return false
        }
    }

    var supportsSignatureVerification: Bool {
        switch self {
        case .getHostedCheckoutStatus:
            return false
        }
    }

    var needsNonceForSigning: Bool {
        switch self {
        case .getHostedCheckoutStatus:
            return false
        }
    }

    var relativePath: String {
        switch self {
        case let .getHostedCheckoutStatus(operationSessionID, appUserID):
            return "/rcbilling/v1/hosted-checkout/\(operationSessionID.trimmedAndEscaped)" +
            "?app_user_id=\(appUserID.trimmedAndEscapedForQuery)"
        }
    }

    var relativeIAMPath: String {
        switch self {
        case .getHostedCheckoutStatus:
            return self.relativePath
        }
    }

    var name: String {
        switch self {
        case .getHostedCheckoutStatus:
            return "get_hosted_checkout_status"
        }
    }

}
