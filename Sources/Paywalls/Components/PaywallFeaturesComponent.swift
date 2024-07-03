//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

public extension PaywallComponent {
    struct FeaturesComponent: PaywallComponentBase {

        let type: String
        public let features: [Feature]
        public let padding: Padding
        public let displayPreferences: [DisplayPreference]?

        public struct Feature: Decodable, Sendable, Hashable, Equatable {
            public init(iconID: String, text: PaywallComponent.LocaleResources<String>) {
                self.iconID = iconID
                self.text = text
            }

            public let iconID: String
            public let text: PaywallComponent.LocaleResources<String>
        }

        public init(
            features: [Feature],
            padding: Padding = .default,
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "features"
            self.features = features
            self.padding = padding
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}
