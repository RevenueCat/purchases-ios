//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SigningStrings.swift
//
//  Created by Nacho Soto on 2/7/23.

import Foundation

// swiftlint:disable identifier_name
enum SigningStrings {

    case invalid_public_key(String)

    case signature_not_base64(String)

    case signature_failed_verification

    case signature_was_requested_but_not_provided(HTTPRequest)

    case request_date_missing_from_headers(HTTPRequest)

    #if DEBUG
    case invalid_signature_data(HTTPRequest, Data, HTTPClient.ResponseHeaders, HTTPStatusCode)
    #endif

}

extension SigningStrings: LogMessage {

    var description: String {
        switch self {
        case let .invalid_public_key(key):
            return "Public key could not be loaded: \(key)"

        case let .signature_not_base64(signature):
            return "Signature is not base64: \(signature)"

        case .signature_failed_verification:
            return "Signature failed verification"

        case let .request_date_missing_from_headers(request):
            return "Request to '\(request.path)' required a request date but none was provided. " +
            "This will be reported as a verification failure."

        case let .signature_was_requested_but_not_provided(request):
            return "Request to '\(request.path)' required a signature but none was provided. " +
            "This will be reported as a verification failure."

        #if DEBUG
        case let .invalid_signature_data(request, data, responseHeaders, statusCode):
            return """
            INVALID SIGNATURE DETECTED:
            Request: \(request.method.httpMethod) \(request.path)
            Response: \(statusCode.rawValue)
            \(responseHeaders.stringRepresentation)
            Headers: \(responseHeaders.map { "\($0.key.base): \($0.value)" })
            Body (length: \(data.count)): \(data.hashString)
            """

        #endif
        }
    }

    var category: String { return "signing" }

}
