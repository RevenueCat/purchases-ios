//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventHTTPRequestPath.swift
//
//  Created by RevenueCat.

import Foundation

/// Protocol for event-related HTTP request paths that share common behavior.
/// Conforming types only need to provide `serverHostURL` and `name`.
protocol EventHTTPRequestPath: HTTPRequestPath {

    var relativePath: String { get }
    var name: String { get }

}

extension EventHTTPRequestPath {

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

}
