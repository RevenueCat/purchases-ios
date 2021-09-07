//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Dictionary+Extensions.swift
//
//  Created by César de la Vega on 7/21/21.
//

import Foundation

extension Dictionary {

    func removingNSNullValues() -> Dictionary {
        self.filter { !($0.value is NSNull) }
    }

}

extension Dictionary {

    /// Merge strategy to use for any duplicate keys.
    enum MergeStrategy<Value> {

        /// Keep the original value.
        case keepOriginalValue
        /// Overwrite the original value.
        case overwriteValue

        var combine: (Value, Value) -> Value {
            switch self {
            case .keepOriginalValue:
                return { original, _ in original }
            case .overwriteValue:
                return { _, overwrite in overwrite }
            }
        }

    }

    /// Creates a dictionary by merging the given dictionary into this
    /// dictionary, using a merge strategy to determine the value for
    /// duplicate keys.
    ///
    /// - Parameters:
    ///   - other:  A dictionary to merge.
    ///   - strategy: The merge strategy to use for any duplicate keys. The strategy provides a
    ///   closure that returns the desired value for the final dictionary. The default is `overwriteValue`.
    /// - Returns: A new dictionary with the combined keys and values of this
    ///   dictionary and `other`.
    func merging(_ other: [Key: Value], strategy: MergeStrategy<Value> = .overwriteValue) -> [Key: Value] {
        merging(other, uniquingKeysWith: strategy.combine)
    }

    /// Merge the keys/values of two dictionaries.
    ///
    /// The merge strategy used is `overwriteValue`.
    ///
    /// - Parameters:
    ///   - lhs: A dictionary to merge.
    ///   - rhs: Another dictionary to merge.
    /// - Returns: An dictionary with keys and values from both.
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs)
    }

}
