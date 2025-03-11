//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallHTTPRequestPath.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation

extension HTTPRequest.PaywallPath: HTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://api-paywalls.revenuecat.com")!

    var authenticated: Bool {
        switch self {
        case .postEvents:
            return true
        }
    }

    var shouldSendEtag: Bool {
        switch self {
        case .postEvents:
            return false
        }
    }

    var supportsSignatureVerification: Bool {
        switch self {
        case .postEvents:
            return false
        }
    }

    var needsNonceForSigning: Bool {
        switch self {
        case .postEvents:
            return false
        }
    }

    var pathComponent: String {
        switch self {
        case .postEvents:
            return "events"
        }
    }

    var name: String {
        switch self {
        case .postEvents:
            return "post_paywall_events"
        }
    }

}
