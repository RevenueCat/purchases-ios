//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsHTTPRequestPath.swift
//
//  Created by RevenueCat on 10/30/25.

import Foundation

/// Protocol for events endpoints that share common configuration.
/// Both FeatureEvents and AdEvents use the same `/v1/events` endpoint
/// but with different domains.
protocol EventsHTTPRequestPath: HTTPRequestPath {}

extension EventsHTTPRequestPath {

    var authenticated: Bool {
        return true
    }

    var shouldSendEtag: Bool {
        return false
    }

    var supportsSignatureVerification: Bool {
        return false
    }

    var needsNonceForSigning: Bool {
        return false
    }

    var relativePath: String {
        return "/v1/events"
    }

}
