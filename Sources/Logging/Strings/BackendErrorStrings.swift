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

}

extension BackendErrorStrings: CustomStringConvertible {

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
        }
    }

}
