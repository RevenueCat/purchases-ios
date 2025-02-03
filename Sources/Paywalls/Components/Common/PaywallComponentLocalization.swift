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

extension PaywallComponent.LocalizationDictionary {

    public func string(key: String) throws -> String {
        guard case let .string(value) = self[key] else {
            throw LocalizationValidationError.missingLocalization(
                "Missing string localization for property with id: \"\(key)\""
            )
        }
        return value
    }

    public func image(key: String) throws -> PaywallComponent.ThemeImageUrls {
        guard case let .image(value) = self[key] else {
            throw LocalizationValidationError.missingLocalization(
                "Missing image localization for property with id: \"\(key)\""
            )
        }
        return value
    }

}

enum LocalizationValidationError: Error {

    case missingLocalization(String)
    case invalidUrl(String)

}
