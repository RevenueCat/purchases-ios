//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentsData.swift
//
//  Created by Josh Holtz on 11/11/24.
// swiftlint:disable identifier_name missing_docs

import Foundation

public struct PaywallComponentsData: Codable, Equatable, Sendable {

    public struct ComponentsConfig: Codable, Equatable, Sendable {

        public var base: PaywallComponentsConfig

        public init(base: PaywallComponentsConfig) {
            self.base = base
        }

    }

    public struct PaywallComponentsConfig: Codable, Equatable, Sendable {

        public var stack: PaywallComponent.StackComponent
        public let stickyFooter: PaywallComponent.StickyFooterComponent?
        public var background: PaywallComponent.Background

        public init(
            stack: PaywallComponent.StackComponent,
            stickyFooter: PaywallComponent.StickyFooterComponent?,
            background: PaywallComponent.Background
        ) {
            self.stack = stack
            self.stickyFooter = stickyFooter
            self.background = background
        }

    }

    public enum LocalizationData: Codable, Equatable, Sendable {
        case string(String), image(PaywallComponent.ThemeImageUrls)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let imageValue = try? container.decode(PaywallComponent.ThemeImageUrls.self) {
                self = .image(imageValue)
            } else {
                throw DecodingError.typeMismatch(
                    LocalizationData.self,
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "Wrong type for LocalizationData")
                )
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let stringValue):
                try container.encode(stringValue)
            case .image(let imageValue):
                try container.encode(imageValue)
            }
        }
    }

    public var templateName: String

    /// The base remote URL where assets for this paywall are stored.
    public var assetBaseURL: URL

    /// The revision identifier for this paywall.
    public var revision: Int {
        get { return self._revision }
        set { self._revision = newValue }
    }

    public var componentsConfig: ComponentsConfig
    public var componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary]
    public var defaultLocale: String

    @DefaultDecodable.Zero
    internal private(set) var _revision: Int = 0

    public var errorInfo: [String: EquatableError]?

    private enum CodingKeys: String, CodingKey {
        case templateName
        case componentsConfig
        case componentsLocalizations
        case defaultLocale
        case assetBaseURL = "assetBaseUrl"
        case _revision = "revision"
    }

    public init(templateName: String,
                assetBaseURL: URL,
                componentsConfig: ComponentsConfig,
                componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
                revision: Int,
                defaultLocaleIdentifier: String) {
        self.templateName = templateName
        self.assetBaseURL = assetBaseURL
        self.componentsConfig = componentsConfig
        self.componentsLocalizations = componentsLocalizations
        self._revision = revision
        self.defaultLocale = defaultLocaleIdentifier
    }

}

extension PaywallComponentsData {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var errors: [String: EquatableError] = [:]

        do {
            templateName = try container.decode(String.self, forKey: .templateName)
        } catch {
            errors["templateName"] = .init(error)
            templateName = ""
        }

        do {
            assetBaseURL = try container.decode(URL.self, forKey: .assetBaseURL)
        } catch {
            errors["assetBaseURL"] = .init(error)
            // swiftlint:disable:next force_unwrapping
            assetBaseURL = URL(string: "https://example.com")!
        }

        do {
            componentsConfig = try container.decode(ComponentsConfig.self, forKey: .componentsConfig)
        } catch {
            errors["componentsConfig"] = .init(error)
            componentsConfig = ComponentsConfig(base: PaywallComponentsConfig(
                stack: .init(components: []),
                stickyFooter: nil,
                background: .color(.init(light: .hex("#ffffff")))
            ))
        }

        do {
            componentsLocalizations = try container.decode(
                [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary].self,
                forKey: .componentsLocalizations
            )
        } catch {
            errors["componentsLocalizations"] = .init(error)
            componentsLocalizations = [:]
        }

        do {
            defaultLocale = try container.decode(String.self, forKey: .defaultLocale)
        } catch {
            errors["defaultLocale"] = .init(error)
            defaultLocale = "en"
        }

        do {
            _revision = try container.decode(Int.self, forKey: ._revision)
        } catch {
            errors["_revision"] = .init(error)
            _revision = 0
        }

        if !errors.isEmpty {
            errorInfo = errors
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(templateName, forKey: .templateName)
        try container.encode(assetBaseURL, forKey: .assetBaseURL)
        try container.encode(componentsConfig, forKey: .componentsConfig)
        try container.encode(componentsLocalizations, forKey: .componentsLocalizations)
        try container.encode(defaultLocale, forKey: .defaultLocale)
        try container.encode(_revision, forKey: ._revision)
    }

}

extension PaywallComponentsData {

    public struct EquatableError: Equatable, Sendable {
        let description: String

        init(_ error: Error) {
            self.description = String(describing: error)
        }

        public static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
            return lhs.description == rhs.description
        }
    }

}
