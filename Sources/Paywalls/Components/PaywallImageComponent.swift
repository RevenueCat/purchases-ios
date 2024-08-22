//
//  PaywallImageComponent.swift
//
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation
// swiftlint:disable all

#if PAYWALL_COMPONENTS

public extension PaywallComponent {
    struct ImageComponent: PaywallComponentBase {

        let type: String
        public let url: URL

        public init(
            url: URL
        ) {
            self.type = "image"
            self.url = url
        }

    }
}

#endif
