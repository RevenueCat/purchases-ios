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

    case signature_invalid_size(Data)

    case signature_failed_verification
    case signature_passed_verification

    case request_failed_verification(HTTPRequest)

    case intermediate_key_failed_verification(signature: Data)
    case intermediate_key_failed_creation(Error)
    case intermediate_key_expired(Date, Data)
    case intermediate_key_invalid(Data)
    case intermediate_key_creating(expiration: Date, data: Data)

    case signature_was_requested_but_not_provided(HTTPRequest)

    case request_date_missing_from_headers(HTTPRequest)

    #if DEBUG
    case verifying_signature(signature: Data,
                             publicKey: Data,
                             parameters: Signing.SignatureParameters,
                             salt: Data,
                             payload: Data,
                             message: Data?)
    case invalid_signature_data(HTTPRequest, Data?, HTTPClient.ResponseHeaders, HTTPStatusCode)
    #endif

}

extension SigningStrings: LogMessage {

    var description: String {
        switch self {
        case let .invalid_public_key(key):
            return "Public key could not be loaded: \(key)"

        case let .signature_not_base64(signature):
            return "Signature is not base64: \(signature)"

        case let .signature_invalid_size(signature):
            return "Signature '\(signature)' does not have expected size (\(Signing.SignatureComponent.totalSize)). " +
            "Verification failed."

        case .signature_failed_verification:
            return "Signature failed verification"

        case .signature_passed_verification:
            return "Signature passed verification"

        case let .request_failed_verification(request):
            return "Request to \(request.path) failed verification. This is likely due to " +
            "a malicious user intercepting and modifying requests."

        case let .intermediate_key_failed_verification(signature):
            return "Intermediate key failed verification: \(signature.asString)"

        case let .intermediate_key_failed_creation(error):
            return "Failed initializing intermediate key: \(error.localizedDescription)\n" +
            "This will be reported as a verification failure."

        case let .intermediate_key_expired(date, data):
            return "Intermediate key expired at '\(date)' (parsed from '\(data.asString)'). " +
            "This will be reported as a verification failure."

        case let .intermediate_key_invalid(expirationDate):
            return "Found invalid intermediate key expiration date: \(expirationDate.asString). " +
            "This will be reported as a verification failure."

        case let .intermediate_key_creating(expiration, data):
            return "Creating intermediate key with expiration '\(expiration)': \(data.asString)"

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
            Request: \(request.method.httpMethod) \(request.path.relativePath)
            Response: \(statusCode.rawValue)
            Headers: \(responseHeaders.map { "\($0.key.base): \($0.value)" })
            Body (length: \(data?.count ?? 0)): \(data?.hashString ?? "<>")
            """

        case let .verifying_signature(
            signature,
            publicKey,
            parameters,
            salt,
            payload,
            message
        ):
            return """
            Verifying signature '\(signature.base64EncodedString())'
            Public key: '\(publicKey.asString)'
            Parameters: \(parameters)
            Salt: \(salt.base64EncodedString()),
            Payload: \(payload.base64EncodedString()),
            Message: \(message?.base64EncodedString() ?? "")
            """

        #endif
        }
    }

    var category: String { return "signing" }

}
