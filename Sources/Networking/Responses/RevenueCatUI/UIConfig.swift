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

#if !os(tvOS) // For Paywalls V2

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
        @_spi(Internal) public let ios: FontInfo

        @_spi(Internal) public init(ios: FontInfo) {
            self.ios = ios
        }
    }

    @_spi(Internal) public struct FontInfo: Codable, Sendable, Hashable {
        @_spi(Internal) public let type: FontInfoType
        @_spi(Internal) public let value: String
        let webFontInfo: WebFontInfo?

        @_spi(Internal) public init(name: String, webFontInfo: WebFontInfo? = nil) {
            self.type = .name
            self.value = name
            self.webFontInfo = webFontInfo
        }

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case type
            case value
        }

        @_spi(Internal) public init(from decoder: Decoder) throws {
            self.webFontInfo = try? WebFontInfo(from: decoder)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(FontInfoType.self, forKey: .type)
            self.value = try container.decode(String.self, forKey: .value)
        }

        @_spi(Internal) public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: UIConfig.FontInfo.CodingKeys.self)
            try container.encode(self.type, forKey: UIConfig.FontInfo.CodingKeys.type)
            try container.encode(self.value, forKey: UIConfig.FontInfo.CodingKeys.value)
        }

        // swiftlint:disable:next nesting
        @_spi(Internal) public enum FontInfoType: String, Codable, Sendable {
            case name
            case googleFonts = "google_fonts"
        }
    }

    @_spi(Internal) public struct WebFontInfo: Codable, Sendable, Hashable {

        /// The font family name.
        internal let family: String?

        /// The remote URL to the font resource file.
        internal let url: String

        /// MD5 hash of the font file.
        ///
        /// Should never be `nil`, but it is optional to prevent potential decoding errors if, for some reason,
        /// the hash is not provided from the server.
        internal let hash: String

        @_spi(Internal) public init(url: String, hash: String) {
            self.family = nil
            self.url = url
            self.hash = hash
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
