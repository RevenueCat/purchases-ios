//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/25/24.
//

import Foundation

public extension PaywallComponent {
    struct CarouselComponent: PaywallComponentBase {

        let type: String
        public let urls: [URL]
        public let displayPreferences: [DisplayPreference]?

        public init(
            urls: [URL],
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "carousel"
            self.urls = urls
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}
