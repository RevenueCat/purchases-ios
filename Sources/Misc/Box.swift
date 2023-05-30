//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Box.swift
//
//  Created by Nacho Soto on 8/19/22.

import Foundation

// Workaround for https://openradar.appspot.com/radar?id=4970535809187840 / https://github.com/apple/swift/issues/58099
/// Holds a reference to a value.
final class Box<T> {

    let value: T

    init(_ value: T) { self.value = value }

}

/// Holds a weak reference to an object.
final class WeakBox<T: AnyObject> {

    private(set) weak var value: T?

    init(_ value: T) { self.value = value }

}

extension Box: Sendable where T: Sendable {}
