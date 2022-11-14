//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncTestHelpers.swift
//
//  Created by Nacho Soto on 11/14/22.

import Foundation

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
internal extension AsyncSequence {

    /// Returns the elements of the asynchronous sequence.
    func extractValues() async rethrows -> [Element] {
        return try await self.reduce(into: []) {
            $0.append($1)
        }
    }

}
