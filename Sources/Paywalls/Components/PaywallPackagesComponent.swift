//
//  File.swift
//  
//
//  Created by James Borthwick on 9/5/24.
//

import Foundation
// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct PackagesComponent: PaywallComponentBase {

        let type: ComponentType
        public let defaultSelectedPackageID: String
        public let components: [PaywallComponent]

        public init(type: ComponentType, defaultSelectedPackageID: String, components: [PaywallComponent]) {
            self.type = .packages
            self.defaultSelectedPackageID = defaultSelectedPackageID
            self.components = components
        }

    }

}

#endif
