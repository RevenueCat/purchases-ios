//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

public extension PaywallComponent {
    struct PackagesComponent: PaywallComponentBase {

        let type: String
        public let packages: Packages
        public let displayPreferences: [DisplayPreference]?

        public init(
            packages: Packages,
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "packages"
            self.packages = packages
            self.displayPreferences = displayPreferences
        }

        public var focusIdentifiers: [FocusIdentifier]? = {
            return [UUID.init().uuidString]
        }()

    }
}
