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

    case signature_not_base64(String)

    case signature_failed_verification

}

extension SigningStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case let .signature_not_base64(signature):
            return "Signature is not base64: \(signature)"

        case .signature_failed_verification:
            return "Signature failed validation"
        }
    }

}
