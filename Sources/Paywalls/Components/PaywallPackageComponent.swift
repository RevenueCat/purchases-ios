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

    final class PackageComponent: PaywallComponentBase {

        let type: ComponentType
        public let packageID: String
        public let isSelectedByDefault: Bool
        public let stack: PaywallComponent.StackComponent

        public init(
            packageID: String,
            isSelectedByDefault: Bool,
            stack: PaywallComponent.StackComponent
        ) {
            self.type = .package
            self.packageID = packageID
            self.isSelectedByDefault = isSelectedByDefault
            self.stack = stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(packageID)
            hasher.combine(isSelectedByDefault)
            hasher.combine(stack)
        }

        public static func == (lhs: PackageComponent, rhs: PackageComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.packageID == rhs.packageID &&
                   lhs.isSelectedByDefault == rhs.isSelectedByDefault &&
                   lhs.stack == rhs.stack
        }
    }

}

extension PaywallComponent.PackageComponent {

    enum CodingKeys: String, CodingKey {
        case type
        case packageID = "packageId"
        case isSelectedByDefault
        case stack
    }

}
