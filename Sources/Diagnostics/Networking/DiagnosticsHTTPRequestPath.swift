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

extension HTTPRequest.DiagnosticsPath: HTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://api-diagnostics.revenuecat.com")!

    var authenticated: Bool {
        switch self {
        case .postDiagnostics:
            return true
        }
    }

    var shouldSendEtag: Bool {
        switch self {
        case .postDiagnostics:
            return false
        }
    }

    var supportsSignatureVerification: Bool {
        switch self {
        case .postDiagnostics:
            return false
        }
    }

    var needsNonceForSigning: Bool {
        switch self {
        case .postDiagnostics:
            return false
        }
    }

    var pathComponent: String {
        switch self {
        case .postDiagnostics:
            return "diagnostics"
        }
    }

    var name: String {
        switch self {
        case .postDiagnostics:
            return "post_diagnostics"
        }
    }

}
