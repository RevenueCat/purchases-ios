//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIConfig.swift
//
//  Created by Josh Holtz on 12/31/24.
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public struct UIConfig: Codable, Equatable, Sendable {

    public struct AppConfig: Codable, Equatable, Sendable {

        public var colors: [String: PaywallComponent.ColorInfo]
        public var fonts: FontsConfig

        public init(colors: [String: PaywallComponent.ColorInfo],
                    fonts: FontsConfig) {
            self.colors = colors
            self.fonts = fonts
        }

    }

    public struct FontsConfig: Codable, Equatable, Sendable {

        public var ios: FontInfo

        public init(ios: FontInfo) {
            self.ios = ios
        }

    }

    public enum FontInfo: Codable, Sendable, Hashable {

        // Other platforms support types like "google_fonts"
        // This will only support "name" for now
        case name(String)

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .name(let name):
                try container.encode(FontInfoTypes.name.rawValue, forKey: .type)
                try container.encode(name, forKey: .value)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(FontInfoTypes.self, forKey: .type)

            switch type {
            case .name:
                let value = try container.decode(String.self, forKey: .value)
                self = .name(value)
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case value

        }

        // swiftlint:disable:next nesting
        private enum FontInfoTypes: String, Decodable {

            case name

        }

    }

    public struct MappingConfig: Codable, Equatable, Sendable {

        public var variables: [String: String]
        public var functions: [String: String]

        public init(variables: [String: String], functions: [String: String]) {
            self.variables = variables
            self.functions = functions
        }

    }

    public var app: AppConfig
    public var localizations: [String: [String: String]]
    public var mapping: MappingConfig

    public init(app: AppConfig,
                localizations: [String: [String: String]],
                mapping: MappingConfig) {
        self.app = app
        self.localizations = localizations
        self.mapping = mapping
    }

}

#endif
