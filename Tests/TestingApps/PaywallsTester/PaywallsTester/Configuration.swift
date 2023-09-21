//
//  Configuration.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation

enum Configuration {

    #warning("Configure API key if you want to test paywalls from your dashboard")

    // Note: you can leave this empty to use the production server, or point to your own instance.
    static let proxyURL = ""
    static let apiKey = ""

    static let entitlement = "pro"

}

extension Configuration {

    static var effectiveApiKey: String = {
        return Self.apiKey.nonEmpty ?? Self.apiKeyFromCI
    }()

    // This is modified by CI:
    private static let apiKeyFromCI = ""

}

// MARK: - Extensions

private extension String {

    var nonEmpty: String? { return self.isEmpty ? nil : self }

}
