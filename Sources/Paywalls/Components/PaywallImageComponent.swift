//
//  PaywallImageComponent.swift
//
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

public extension PaywallComponent {
    struct ImageComponent: Decodable, Sendable, Hashable, Equatable {

        let type: String
        public let url: URL

        public init(url: URL) {
            self.type = "image"
            self.url = url
        }

    }
}
