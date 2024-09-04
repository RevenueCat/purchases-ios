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

public typealias LocaleID = String
public typealias LocalizationDictionary = [String: String]
public typealias LocalizationKey = String

extension LocalizationDictionary {

    public func string<T: PaywallComponentBase>(
        for keyPath: KeyPath<T, LocalizationKey?>,
        from component: T
    ) throws -> String {
        guard let stringID = component[keyPath: keyPath] else {
            let propertyName = "\(keyPath)"
            throw LocalizationValidationError.missingLocalization(
                "Required localization ID \(propertyName) is null."
            )
        }
        guard let value = self[stringID] else {
            let propertyName = "\(keyPath)"
            throw LocalizationValidationError.missingLocalization(
                "Missing localization for property \(propertyName) with id: \"\(stringID)\""
            )
        }
        return value
    }

}

enum LocalizationValidationError: Error {

    case missingLocalization(String)

}

#endif
