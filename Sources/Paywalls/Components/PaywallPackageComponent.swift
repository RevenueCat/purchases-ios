//
//  PackageComponent.swift
//
//
//  Created by James Borthwick on 9/6/24.

import Foundation
// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct PackageComponent: PaywallComponentBase {

        let type: ComponentType
        public let packageID: String
        public let components: [PaywallComponent]

        public init(type: ComponentType, packageID: String, components: [PaywallComponent]) {
            self.type = .package
            self.packageID = packageID
            self.components = components
        }

    }

}

#endif
