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
        public let displayPreferences: [DisplayPreference]?

        public init(
            url: URL,
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "image"
            self.url = url
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}

#endif
