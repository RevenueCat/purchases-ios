//
//  PaywallTiersComponent.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import Foundation
// swiftlint:disable all

#if PAYWALL_COMPONENTS

public extension PaywallComponent {
    struct TiersComponent: PaywallComponentBase {


        let type: String
        public let tiers: [TierInfo]
        public let displayPreferences: [DisplayPreference]?

        public struct TierInfo: Decodable, Sendable, Hashable, Equatable {
            public init(id: String, displayName: PaywallComponent.LocaleResources<String>, components: [PaywallComponent]) {
                self.id = id
                self.displayName = displayName
                self.components = components
            }
            
            public let id: String
            public let displayName: PaywallComponent.LocaleResources<String>
            public let components: [PaywallComponent]
        }

        public init(
            tiers: [TierInfo],
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "tiers"
            self.tiers = tiers
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}

public extension PaywallComponent {
    struct TierSelectorComponent: PaywallComponentBase {

        let type: String
        public let displayPreferences: [DisplayPreference]?

        public init(
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "tier_selector"
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}

public extension PaywallComponent {
    struct TierToggleComponent: PaywallComponentBase {

        let type: String
        public let text: DisplayString
        public let defaultValue: Bool
        public let color: ColorInfo
        public let textStyle: TextStyle
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorInfo?
        public let padding: Padding
        public let displayPreferences: [DisplayPreference]?

        public init(
            text: DisplayString,
            defaultValue: Bool = false,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            textStyle: TextStyle = .body,
            horitzontalAlignment: HorizontalAlignment = .center,
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "text"
            self.text = text
            self.defaultValue = defaultValue
            self.color = color
            self.backgroundColor = backgroundColor
            self.padding = padding
            self.textStyle = textStyle
            self.horizontalAlignment = horitzontalAlignment
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}

#endif
