//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallData.swift
//
//  Created by Nacho Soto on 7/10/23.

import Foundation

/// The data necessary to display a paywall using the `RevenueCatUI` library.
/// They can be created and configured in the dashboard, then access from ``Offering/paywall``.
public struct PaywallData {

    /// The type of template used to display this paywall.
    public var template: PaywallTemplate

    /// Generic configuration for any paywall.
    public var config: Configuration

    fileprivate var defaultLocaleIdentifier: String
    fileprivate var localization: [String: LocalizedConfiguration]

}

extension PaywallData {

    /// Configuration containing values for the necessary `Locale`s.
    public struct LocalizedConfiguration {

        /// The content of the main action button for purchasing a subscription.
        public let callToAction: String
        /// The title of the paywall screen.
        public let title: String

        /// swiftlint:disable:next missing_docs
        public init(callToAction: String, title: String) {
            self.callToAction = callToAction
            self.title = title
        }

    }

    /// - Returns: ``PaywallData/LocalizedConfiguration-swift.struct`` for the given `Locale`, if found.
    public func config(for locale: Locale) -> LocalizedConfiguration? {
        return self.localization[locale.identifier]
    }

    /// The default `Locale` used if `Locale.current` is not configured for this paywall.
    public var defaultLocale: Locale {
        return .init(identifier: self.defaultLocaleIdentifier)
    }

    /// - Returns: the ``PaywallData/LocalizedConfiguration-swift.struct`` associated to the current `Locale`
    /// or the configuration associated to ``defaultLocale``.
    public var localizedConfiguration: LocalizedConfiguration {
        return self.config(for: Locale.current) ?? self.defaultLocalizedConfiguration
    }

    private var defaultLocalizedConfiguration: LocalizedConfiguration {
        let defaultLocale = self.defaultLocale

        guard let result = self.config(for: defaultLocale) else {
            fatalError(
                "Corrupted data. Expected to find locale \(defaultLocale.identifier) " +
                "in locales: \(Set(self.localization.keys))"
            )
        }

        return result
    }

}

extension PaywallData {

    /// Generic configuration for any paywall.
    public struct Configuration {

        // swiftlint:disable:next missing_docs
        public init() {}

    }

}

// MARK: - Constructors

extension PaywallData {

    init(
        template: PaywallTemplate,
        config: Configuration,
        defaultLocale: String,
        localization: [String: LocalizedConfiguration]
    ) {
        self.template = template
        self.config = config
        self.defaultLocaleIdentifier = defaultLocale
        self.localization = localization
    }

    /// Creates a test ``PaywallData`` with one localization
    public init(
        template: PaywallTemplate,
        config: Configuration,
        localization: LocalizedConfiguration
    ) {
        let locale = Locale.current.identifier

        self.init(
            template: template,
            config: config,
            defaultLocale: locale,
            localization: [locale: localization]
        )
    }

}

// MARK: - Codable

extension PaywallData.LocalizedConfiguration: Codable {

    private enum CodingKeys: String, CodingKey {
        case callToAction = "cta"
        case title
    }

}
extension PaywallData.Configuration: Codable {}
extension PaywallData: Codable {

    // Note: these are camel case but converted by the decoder
    private enum CodingKeys: String, CodingKey {
        case template = "templateName"
        case defaultLocaleIdentifier = "defaultLocale"
        case config
        case localization = "localizedStrings"
    }

}

// MARK: - Equatable

extension PaywallData.LocalizedConfiguration: Equatable {}
extension PaywallData.Configuration: Equatable {}
extension PaywallData: Equatable {}

// MARK: - Sendable

extension PaywallData.LocalizedConfiguration: Sendable {}
extension PaywallData.Configuration: Sendable {}
extension PaywallData: Sendable {}
