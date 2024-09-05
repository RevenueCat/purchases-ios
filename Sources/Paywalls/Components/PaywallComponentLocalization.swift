//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentLocalization.swift
//
//  Created by James Borthwick on 2024-09-03.
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

extension PaywallComponent.LocalizationDictionary {

    public func string(key: String) throws -> String {
        guard let value = self[key] else {
            throw LocalizationValidationError.missingLocalization(
                "Missing localization for property with id: \"\(key)\""
            )
        }
        return value
    }

}

enum LocalizationValidationError: Error {

    case missingLocalization(String)

}

#endif
