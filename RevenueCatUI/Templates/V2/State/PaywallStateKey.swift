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

/// Fully-scoped key for a single paywall state slot.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateKey: Hashable, Sendable {

    @_spi(Internal) public struct Field: Hashable, Sendable, RawRepresentable {

        @_spi(Internal) public let rawValue: String

        @_spi(Internal)
        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        @_spi(Internal) public static let rootSelectedPackageID = Field(
            rawValue: "paywall.root_selected_package_id"
        )

        @_spi(Internal)
        public static func component(_ propertyPath: String) -> Field {
            Field(rawValue: "component.\(propertyPath)")
        }

        @_spi(Internal)
        public static func sheetSelectedPackageID(componentID: String) -> Field {
            Field(rawValue: "paywall.sheet[\(componentID)].selected_package_id")
        }

    }

    @_spi(Internal) public let scope: PaywallStateScope
    @_spi(Internal) public let component: PaywallComponentIdentity
    @_spi(Internal) public let field: Field

    @_spi(Internal)
    public init(
        scope: PaywallStateScope,
        component: PaywallComponentIdentity,
        field: Field
    ) {
        self.scope = scope
        self.component = component
        self.field = field
    }

    @_spi(Internal)
    public static func paywall(scope: PaywallStateScope, field: Field) -> PaywallStateKey {
        PaywallStateKey(
            scope: scope,
            component: PaywallComponentIdentity(
                paywallID: scope.paywallID,
                componentID: "paywall",
                type: "paywall",
                name: nil
            ),
            field: field
        )
    }

}

// swiftlint:enable missing_docs

#endif
