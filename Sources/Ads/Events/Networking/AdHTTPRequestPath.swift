//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdHTTPRequestPath.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation

extension HTTPRequest.AdPath: HTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://e.revenue.cat")!

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

    var relativePath: String {
        switch self {
        case .postEvents:
            return "/v1/events"
        }
    }

    var name: String {
        switch self {
        case .postEvents:
            return "post_ad_events"
        }
    }

}
