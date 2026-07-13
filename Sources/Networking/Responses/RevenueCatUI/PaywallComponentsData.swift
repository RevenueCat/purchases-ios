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

@_spi(Internal) public struct PaywallComponentsData: Codable, Equatable, Sendable {

    public struct ComponentsConfig: Codable, Equatable, Sendable {

        public var base: PaywallComponentsConfig

        public init(base: PaywallComponentsConfig) {
            self.base = base
        }

    }

    public struct PaywallComponentsConfig: Codable, Equatable, Sendable {

        public var stack: PaywallComponent.StackComponent
        @_spi(Internal) public let header: PaywallComponent.HeaderComponent?
        public let stickyFooter: PaywallComponent.StickyFooterComponent?
        public var background: PaywallComponent.Background

        public init(
            stack: PaywallComponent.StackComponent,
            stickyFooter: PaywallComponent.StickyFooterComponent?,
            background: PaywallComponent.Background
        ) {
            self.header = nil
            self.stack = stack
            self.stickyFooter = stickyFooter
            self.background = background
        }

        @_spi(Internal) public init(
            stack: PaywallComponent.StackComponent,
            header: PaywallComponent.HeaderComponent?,
            stickyFooter: PaywallComponent.StickyFooterComponent?,
            background: PaywallComponent.Background
        ) {
            self.stack = stack
            self.header = header
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

    /// The unique identifier for this paywall.
    public var id: String?

    public var templateName: String

    /// The base remote URL where assets for this paywall are stored.
    public var assetBaseURL: URL

    /// The revision identifier for this paywall.
    public var revision: Int {
        get { return self._revision }
        set { self._revision = newValue }
    }

    /// The storefront country codes that should display whole number prices without decimal places.
    /// For example, in these countries "$60.00" would be displayed as "$60".
    public private(set) var zeroDecimalPlaceCountries: [String] = []

    public var componentsConfig: ComponentsConfig
    public var componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary]
    public var defaultLocale: String

    /// Exit offers configuration for this paywall.
    public var exitOffers: ExitOffers?

    /// Declared paywall state keys (key → type + default), used to seed the presentation-session
    /// state store. Declared at the root of the presentation unit; `nil` when the paywall declares
    /// no state, which behaves identically to an empty declaration.
    public private(set) var stateDeclarations: [String: PaywallComponent.StateDeclaration]?

    /// When `false`, paywall text will not respect Dynamic Type and would use fixed sizing. Otherwise it will scale.
    public var automaticallyScaleFontSize: Bool

    @DefaultDecodable.Zero
    internal private(set) var _revision: Int = 0

    public var errorInfo: [String: EquatableError]?

    private enum CodingKeys: String, CodingKey {
        case id
        case templateName
        case componentsConfig
        case componentsLocalizations
        case defaultLocale
        case assetBaseURL = "assetBaseUrl"
        case _revision = "revision"
        case zeroDecimalPlaceCountries
        case exitOffers
        case automaticallyScaleFontSize
        case stateDeclarations
    }

    public init(id: String? = nil,
                templateName: String,
                assetBaseURL: URL,
                componentsConfig: ComponentsConfig,
                componentsLocalizations: [PaywallComponent.LocaleID: PaywallComponent.LocalizationDictionary],
                revision: Int,
                defaultLocaleIdentifier: String,
                zeroDecimalPlaceCountries: [String] = [],
                exitOffers: ExitOffers? = nil,
                automaticallyScaleFontSize: Bool = true,
                stateDeclarations: [String: PaywallComponent.StateDeclaration]? = nil) {
        self.id = id
        self.templateName = templateName
        self.assetBaseURL = assetBaseURL
        self.componentsConfig = componentsConfig
        self.componentsLocalizations = componentsLocalizations
        self._revision = revision
        self.defaultLocale = defaultLocaleIdentifier
        self.zeroDecimalPlaceCountries = zeroDecimalPlaceCountries
        self.exitOffers = exitOffers
        self.automaticallyScaleFontSize = automaticallyScaleFontSize
        self.stateDeclarations = stateDeclarations
    }

}

@_spi(Internal) extension PaywallComponentsData {

    // swiftlint:disable:next function_body_length
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var errors: [String: EquatableError] = [:]

        id = try container.decodeIfPresent(String.self, forKey: .id)

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

        exitOffers = try container.decodeIfPresent(ExitOffers.self, forKey: .exitOffers)

        // Resilient state decoding: malformed entries are dropped individually and a malformed
        // map is ignored entirely, so a bad declaration can never fail the whole paywall.
        //
        // An empty result is normalized to `nil` so that a missing key, an empty `{}` object, and
        // a map whose entries all fail to decode are all represented identically.
        let decodedState = ((try? container.decodeIfPresent(
            [String: FailableStateDeclaration].self,
            forKey: .stateDeclarations
        )) ?? nil)?.compactMapValues(\.declaration)
        stateDeclarations = (decodedState?.isEmpty == false) ? decodedState : nil

        let shouldScale = try container.decodeIfPresent(Bool.self, forKey: .automaticallyScaleFontSize)
        // default behavior should respect the dynamic type settings unless explicitly disabled
        automaticallyScaleFontSize = shouldScale ?? true

        // Decode zeroDecimalPlaceCountries from the nested structure { "apple": [...] }
        if let zeroDecimalData = try container.decodeIfPresent(
            PaywallData.ZeroDecimalPlaceCountries.self,
            forKey: .zeroDecimalPlaceCountries
        ) {
            zeroDecimalPlaceCountries = zeroDecimalData.apple
        } else {
            zeroDecimalPlaceCountries = []
        }

        if !errors.isEmpty {
            errorInfo = errors
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(templateName, forKey: .templateName)
        try container.encode(assetBaseURL, forKey: .assetBaseURL)
        try container.encode(componentsConfig, forKey: .componentsConfig)
        try container.encode(componentsLocalizations, forKey: .componentsLocalizations)
        try container.encode(defaultLocale, forKey: .defaultLocale)
        try container.encode(_revision, forKey: ._revision)
        // Encode zeroDecimalPlaceCountries in the nested structure { "apple": [...] }
        try container.encode(
            PaywallData.ZeroDecimalPlaceCountries(apple: zeroDecimalPlaceCountries),
            forKey: .zeroDecimalPlaceCountries
        )
        try container.encodeIfPresent(exitOffers, forKey: .exitOffers)
        try container.encode(automaticallyScaleFontSize, forKey: .automaticallyScaleFontSize)
        try container.encodeIfPresent(stateDeclarations, forKey: .stateDeclarations)
    }

}

private extension PaywallComponentsData {

    /// Wrapper that swallows per-entry decoding failures so one malformed state declaration
    /// does not discard the rest of the map.
    struct FailableStateDeclaration: Decodable {

        let declaration: PaywallComponent.StateDeclaration?

        init(from decoder: Decoder) throws {
            self.declaration = try? PaywallComponent.StateDeclaration(from: decoder)
        }

    }

}

@_spi(Internal) extension PaywallComponentsData {

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
