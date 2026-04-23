//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendErrorStrings.swift
//
//  Created by Joshua Liebowitz on 10/26/21.

import Foundation

// swiftlint:disable identifier_name
enum BackendErrorStrings {

    // Backend tried to instantiate a CustomerInfo but for some reason it couldn't.
    case customer_info_instantiation_error(response: [String: Any]?)

    // getOfferings response contained no offerings.
    case offerings_response_no_offerings

    // Posting offerIdForSigning failed due to a signature problem.
    case signature_error(signatureDataString: Any?)
    case unknown_reward_verification_status(status: String)
    case unsupported_reward_verification_reward_type(type: String)
    case malformed_reward_verification_reward_payload(type: String)

}

extension BackendErrorStrings: LogMessage {

    var description: String {
        switch self {
        case .customer_info_instantiation_error(let response):
            var message = "Login failed, unable to instantiate \(CustomerInfo.self)"
            if let response = response {
                message += " from:\n \(response.debugDescription)"
            }
            return message
        case .offerings_response_no_offerings:
            return "Offerings response contained no offerings"
        case .signature_error(let signatureDataString):
            return "Missing 'signatureData' or its structure changed:\n\(String(describing: signatureDataString))"
        case let .unknown_reward_verification_status(status):
            return "Received unknown reward verification status: \(status)"
        case let .unsupported_reward_verification_reward_type(type):
            return "Received unsupported reward verification reward type: \(type)"
        case let .malformed_reward_verification_reward_payload(type):
            return "Received malformed reward verification reward payload for type: \(type)"
        }
    }

    var category: String { return "backend" }

}
