//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomVariableKeyValidator.swift
//
//  Created by Rick van der Linden on 8/12/26.
//

import Foundation

private enum CustomVariableKeyValidatorStrings: LogMessage {

    case invalidKey(String)

    var description: String {
        switch self {
        case .invalidKey(let key):
            return "Custom variable key '\(key)' is invalid and will be ignored. " +
                "Keys must start with a letter and contain only letters, numbers, and underscores."
        }
    }

    var category: String { return "custom_variables" }

}

/// The naming policy for developer-supplied custom variable keys.
@_spi(Internal)
public struct CustomVariableKeyValidator {

    private init() {}

    /// Returns whether a key can be addressed using a `custom.<key>` path.
    public static func isValidKey(_ key: String) -> Bool {
        guard let first = key.first, first.isLetter else { return false }
        return key.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    /// Drops invalid keys and, in debug builds, logs a warning for each removed entry.
    public static func validateAndFilter<Value>(_ variables: [String: Value]) -> [String: Value] {
        return variables.filter { key, _ in
            guard Self.isValidKey(key) else {
                #if DEBUG
                Logger.warn(CustomVariableKeyValidatorStrings.invalidKey(key))
                #endif
                return false
            }

            return true
        }
    }

}
