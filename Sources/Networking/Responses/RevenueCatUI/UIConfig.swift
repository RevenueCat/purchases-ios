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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

public struct UIConfig: Codable, Equatable, Sendable {

    public struct AppConfig: Codable, Equatable, Sendable {

        public var colors: [String: PaywallComponent.ColorScheme]
        public var fonts: [String: FontsConfig]

        public init(colors: [String: PaywallComponent.ColorScheme],
                    fonts: [String: FontsConfig]) {
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

        case name(String)
        case googleFonts(String)

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .name(let name):
                try container.encode(FontInfoTypes.name.rawValue, forKey: .type)
                try container.encode(name, forKey: .value)
            case .googleFonts(let name):
                try container.encode(FontInfoTypes.googleFonts.rawValue, forKey: .type)
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
            case .googleFonts:
                let value = try container.decode(String.self, forKey: .value)
                self = .googleFonts(value)
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
            case googleFonts = "google_fonts"

        }

    }

    public struct VariableConfig: Codable, Equatable, Sendable {

        public var variableCompatibilityMap: [String: String]
        public var functionCompatibilityMap: [String: String]

        public init(
            variableCompatibilityMap: [String: String],
            functionCompatibilityMap: [String: String]
        ) {
            self.variableCompatibilityMap = variableCompatibilityMap
            self.functionCompatibilityMap = functionCompatibilityMap
        }

    }

    public var app: AppConfig
    public var localizations: [String: [String: String]]
    public var variableConfig: VariableConfig

    public init(app: AppConfig,
                localizations: [String: [String: String]],
                variableConfig: VariableConfig) {
        self.app = app
        self.localizations = localizations
        self.variableConfig = variableConfig
    }

}

#else

public struct UIConfig: Codable, Equatable, Sendable {

}

#endif
