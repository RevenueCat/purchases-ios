//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

#if !os(tvOS)

// swiftlint:disable missing_docs

/// Observable component identity. Type and name are metadata; uniqueness is paywall ID + component ID.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallComponentIdentity: Hashable, Sendable {

    @_spi(Internal) public let paywallID: String?
    @_spi(Internal) public let componentID: String
    @_spi(Internal) public let type: String
    @_spi(Internal) public let name: String?

    @_spi(Internal)
    public init(
        paywallID: String?,
        componentID: String,
        type: String,
        name: String?
    ) {
        self.paywallID = paywallID
        self.componentID = componentID
        self.type = type
        self.name = name
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.paywallID == rhs.paywallID &&
            lhs.componentID == rhs.componentID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.paywallID)
        hasher.combine(self.componentID)
    }

}

// swiftlint:enable missing_docs

#endif
