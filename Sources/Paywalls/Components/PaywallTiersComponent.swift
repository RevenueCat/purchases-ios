//
//  PaywallTiersComponent.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import Foundation

public extension PaywallComponent {
    struct TiersComponent: Decodable, Sendable, Hashable, Equatable {

        let type: String
        public let tiers: [TierInfo]

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

        public init(tiers: [TierInfo]) {
            self.type = "tiers"
            self.tiers = tiers
        }

    }
}

public extension PaywallComponent {
    struct TierSelectorComponent: Decodable, Sendable, Hashable, Equatable {

        let type: String

        public init() {
            self.type = "tier_selector"
        }

    }
}
