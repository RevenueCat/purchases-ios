//
//  SDKSettings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

/// The SDK-specific settings served through the `sdk_settings` remote config topic.
struct SDKSettings: Decodable, Equatable {

    let diagnostics: Diagnostics

    init(diagnostics: Diagnostics = .init()) {
        self.diagnostics = diagnostics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.diagnostics = try container.decodeIfPresent(Diagnostics.self, forKey: .diagnostics) ?? .init()
    }

    struct Diagnostics: Decodable, Equatable {

        let enabled: Bool

        init(enabled: Bool = false) {
            self.enabled = enabled
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        }

    }

}

private extension SDKSettings {

    enum CodingKeys: String, CodingKey {
        case diagnostics
    }

}

private extension SDKSettings.Diagnostics {

    enum CodingKeys: String, CodingKey {
        case enabled
    }

}
