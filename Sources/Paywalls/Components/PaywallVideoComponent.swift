//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/25/24.
//

import Foundation

public extension PaywallComponent {
    struct VideoComponent: PaywallComponentBase {

        let type: String
        public let url: URL
        public let displayPreferences: [DisplayPreference]?

        public init(
            url: URL,
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "video"
            self.url = url
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}
