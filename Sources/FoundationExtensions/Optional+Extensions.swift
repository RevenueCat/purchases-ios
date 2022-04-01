//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Optional+Extensions.swift
//
//  Created by Nacho Soto on 3/30/22.

import Foundation

/// Protocol definition to be able to use `Optional` as a type.
internal protocol OptionalType {

    associatedtype Wrapped

    var asOptional: Wrapped? { get }

}

extension Optional: OptionalType {

    var asOptional: Wrapped? { return self }

}

// MARK: -

internal extension Optional where Wrapped == String {

    /// Returns `nil` if `self` is an empty string.
    var notEmpty: String? {
        return self.flatMap { $0.notEmpty }
    }

}
