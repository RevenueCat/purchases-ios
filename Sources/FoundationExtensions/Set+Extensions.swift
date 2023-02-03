//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Set+Extensions.swift
//
//  Created by Nacho Soto on 12/15/21.

import Foundation

extension Set {

    /// Creates a `Dictionary` with the keys in the receiver `Set`, and the values provided by `value`.
    func dictionaryWithValues<Value>(_ value: @escaping (Element) -> Value) -> [Element: Value] {
        return Dictionary(uniqueKeysWithValues: self.lazy.map { ($0, value($0)) })
    }

    /// Merge the values of two `Set`s.
    static func + (lhs: Set<Element>, rhs: Set<Element>) -> Set<Element> {
        lhs.union(rhs)
    }

    /// Adds values from `rhs` to `lhs`.
    static func += (lhs: inout Set<Element>, rhs: Set<Element>) {
        lhs.formUnion(rhs)
    }

}
