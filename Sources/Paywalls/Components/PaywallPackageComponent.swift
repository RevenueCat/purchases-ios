//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPackageComponent.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation

// swiftlint:disable missing_docs

@_spi(Internal) public extension PaywallComponent {

    final class PackageComponent: PaywallComponentBase {

        let type: ComponentType
        public let packageID: String
        public let isSelectedByDefault: Bool
        public let visible: Bool?
        @_spi(Internal) public let applePromoOfferProductCode: String?
        public let stack: PaywallComponent.StackComponent

        public let overrides: ComponentOverrides<PartialPackageComponent>?

        public init(
            packageID: String,
            isSelectedByDefault: Bool,
            visible: Bool? = nil,
            applePromoOfferProductCode: String?,
            stack: PaywallComponent.StackComponent,
            overrides: ComponentOverrides<PartialPackageComponent>? = nil
        ) {
            self.type = .package
            self.packageID = packageID
            self.isSelectedByDefault = isSelectedByDefault
            self.visible = visible
            self.applePromoOfferProductCode = applePromoOfferProductCode
            self.stack = stack
            self.overrides = overrides
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(packageID)
            hasher.combine(isSelectedByDefault)
            hasher.combine(visible)
            hasher.combine(applePromoOfferProductCode)
            hasher.combine(stack)
            hasher.combine(overrides)
        }

        public static func == (lhs: PackageComponent, rhs: PackageComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.packageID == rhs.packageID &&
                   lhs.isSelectedByDefault == rhs.isSelectedByDefault &&
                   lhs.visible == rhs.visible &&
                   lhs.applePromoOfferProductCode == rhs.applePromoOfferProductCode &&
                   lhs.stack == rhs.stack &&
                   lhs.overrides == rhs.overrides
        }
    }

    final class PartialPackageComponent: PaywallPartialComponent {

        public let visible: Bool?

        public init(visible: Bool? = nil) {
            self.visible = visible
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
        }

        public static func == (lhs: PartialPackageComponent, rhs: PartialPackageComponent) -> Bool {
            return lhs.visible == rhs.visible
        }
    }

}

extension PaywallComponent.PackageComponent {

    enum CodingKeys: String, CodingKey {
        case type
        case packageID = "packageId"
        case isSelectedByDefault
        case visible
        case applePromoOfferProductCode
        case stack
        case overrides
    }

}
