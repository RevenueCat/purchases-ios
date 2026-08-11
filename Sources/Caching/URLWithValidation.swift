//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLWithValidation.swift
//
//  Created by Jacob Zivan Rakidzich on 10/3/25.

import Foundation

/// A URL paired with an optional checksum for cache validation.
@_spi(Internal) public struct URLWithValidation: Hashable, Sendable {
    /// The remote URL to fetch or warm.
    public let url: URL
    /// Optional checksum used to validate a cached copy of ``url``.
    public let checksum: Checksum?

    /// Creates a validated URL wrapper.
    public init(url: URL, checksum: Checksum?) {
        self.url = url
        self.checksum = checksum
    }
}
