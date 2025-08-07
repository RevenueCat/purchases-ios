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

public extension PaywallComponent {

    final class PackageComponent: PaywallComponentBase, @unchecked Sendable {

        let type: ComponentType
        public let packageID: String
        public let isSelectedByDefault: Bool
        public private(set) var isSelectable: Bool = true
        @_spi(Internal) public let applePromoOfferProductCode: String?
        public let stack: PaywallComponent.StackComponent

        public init(
            packageID: String,
            isSelectable: Bool,
            isSelectedByDefault: Bool,
            applePromoOfferProductCode: String?,
            stack: PaywallComponent.StackComponent
        ) {
            self.type = .package
            self.packageID = packageID
            self.isSelectable = isSelectable
            self.isSelectedByDefault = isSelectedByDefault
            self.applePromoOfferProductCode = applePromoOfferProductCode
            self.stack = stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(packageID)
            hasher.combine(isSelectable)
            hasher.combine(isSelectedByDefault)
            hasher.combine(applePromoOfferProductCode)
            hasher.combine(stack)
        }

        public static func == (lhs: PackageComponent, rhs: PackageComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.packageID == rhs.packageID &&
                   lhs.isSelectedByDefault == rhs.isSelectedByDefault &&
                   lhs.applePromoOfferProductCode == rhs.applePromoOfferProductCode &&
                   lhs.stack == rhs.stack
        }
    }

}

extension PaywallComponent.PackageComponent {

    enum CodingKeys: String, CodingKey {
        case type
        case packageID = "packageId"
        case isSelectedByDefault
        case applePromoOfferProductCode
        case stack
    }

}
