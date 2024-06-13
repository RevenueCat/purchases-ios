//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

public extension PaywallComponent {
    struct PackagesComponent: Decodable, Sendable, Hashable, Equatable {

        let type: String
        public let packages: Packages

        public init(packages: Packages) {
            self.type = "packages"
            self.packages = packages
        }

    }
}
