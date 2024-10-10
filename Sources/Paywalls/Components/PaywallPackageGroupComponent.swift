//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPackageGroupComponent.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation

// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct PackageGroupComponent: PaywallComponentBase {

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

#endif
