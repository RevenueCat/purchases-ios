//
//  PackageGroupComponent.swift
//  
//
//  Created by James Borthwick on 9/5/24.
//

import Foundation
// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    final class PackageGroupComponent: PaywallComponentBase {

        let type: ComponentType
        public let defaultSelectedPackageID: String
        public let components: [PaywallComponent]

        public init(type: ComponentType, defaultSelectedPackageID: String, components: [PaywallComponent]) {
            self.type = .packageGroup
            self.defaultSelectedPackageID = defaultSelectedPackageID
            self.components = components
        }
    }

}

extension PaywallComponent.PackageGroupComponent: Equatable, Hashable {

    public static func == (lhs: PaywallComponent.PackageGroupComponent,
                           rhs: PaywallComponent.PackageGroupComponent
    ) -> Bool {
        return lhs.type == rhs.type &&
               lhs.defaultSelectedPackageID == rhs.defaultSelectedPackageID &&
               lhs.components == rhs.components
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(defaultSelectedPackageID)
        hasher.combine(components)
    }

}

#endif
