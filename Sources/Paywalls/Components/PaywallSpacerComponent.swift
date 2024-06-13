//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

public extension PaywallComponent {
    struct SpacerComponent: Decodable, Sendable, Hashable, Equatable {

        let type: String

        public init() {
            self.type = "spacer"
        }

    }
}
