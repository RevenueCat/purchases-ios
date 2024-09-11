//
//  PackageComponent.swift
//
//
//  Created by James Borthwick on 9/6/24.

import Foundation
// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    final class PackageComponent: PaywallComponentBase {

        let type: ComponentType
        public let packageID: String
        public let components: [PaywallComponent]

        public init(type: ComponentType,
                    packageID: String,
                    components: [PaywallComponent]
        ) {
            self.type = .package
            self.packageID = packageID
            self.components = components
        }

    }

}

extension PaywallComponent.PackageComponent: Equatable, Hashable {

    public static func == (lhs: PaywallComponent.PackageComponent, rhs: PaywallComponent.PackageComponent) -> Bool {
        return lhs.type == rhs.type &&
               lhs.packageID == rhs.packageID &&
               lhs.components == rhs.components
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(packageID)
        hasher.combine(components)
    }

}

#endif
