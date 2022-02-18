//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Array+Extensions.swift
//
//  Created by Nacho Soto on 2/17/22.

import Foundation

extension Array {

    /// Equivalent to `removeFirst()` but it returns `Optional` if the collection is empty.
    mutating func popFirst() -> Element? {
        guard !self.isEmpty else { return nil }

        return self.removeFirst()
    }

}
