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

// swiftlint:disable file_length identifier_name

import Foundation

/// The data necessary to display a paywall using the `RevenueCatUI` library.
/// They can be created and configured in the dashboard, then accessed from ``Offering/paywall``.
///
/// ### Related Articles
/// [Documentation](https://rev.cat/paywalls)
public struct PaywallData {

    /// The type of template used to display this paywall.
    public var templateName: String

    /// Generic configuration for any paywall.
    public var config: Configuration

    /// The base remote URL where assets for this paywall are stored.
    public var assetBaseURL: URL

    /// The revision identifier for this paywall.
    public var revision: Int {
        get { return self._revision }
        set { self._revision = newValue }
    }

    @DefaultDecodable.Zero
    internal private(set) var _revision: Int = 0

    @EnsureNonEmptyCollectionDecodable
    internal private(set) var localization: [String: LocalizedConfiguration]

}

/// Defines the necessary localized information for a paywall.
public protocol PaywallLocalizedConfiguration {

    /// The title of the paywall screen.
    var title: String { get }
    /// The subtitle of the paywall screen.
    var subtitle: String? { get }
    /// The content of the main action button for purchasing a subscription.
    var callToAction: String { get }
    /// The content of the main action button for purchasing a subscription when an intro offer is available.
    /// If `nil`, no information regarding trial eligibility will be displayed.
    var callToActionWithIntroOffer: String? { get }
    /// Description for the offer to be purchased.
    var offerDetails: String? { get }
    /// Description for the offer to be purchased when an intro offer is available.
    /// If `nil`, no information regarding trial eligibility will be displayed.
    var offerDetailsWithIntroOffer: String? { get }
    /// The name representing each of the packages, most commonly a variable.
    var offerName: String? { get }
    /// An optional list of features that describe this paywall.
    var features: [PaywallData.LocalizedConfiguration.Feature] { get }

}

extension PaywallData {

    /// Defines the necessary localized information for a paywall.
    public struct LocalizedConfiguration: PaywallLocalizedConfiguration {

        // Docs inherited from the protocol
        // swiftlint:disable missing_docs

        public var title: String
        public var callToAction: String

        @NonEmptyStringDecodable
        var _subtitle: String?
        @NonEmptyStringDecodable
        var _callToActionWithIntroOffer: String?
        @NonEmptyStringDecodable
        var _offerDetails: String?
        @NonEmptyStringDecodable
        var _offerDetailsWithIntroOffer: String?
        @NonEmptyStringDecodable
        var _offerName: String?
        @DefaultDecodable.EmptyArray
        var _features: [Feature]

        public var subtitle: String? {
            get { return self._subtitle }
            set { self._subtitle = newValue }
        }
        public var callToActionWithIntroOffer: String? {
            get { return self._callToActionWithIntroOffer }
            set { self._callToActionWithIntroOffer = newValue }
        }
        public var offerDetails: String? {
            get { return self._offerDetails }
            set { self._offerDetails = newValue }
        }
        public var offerDetailsWithIntroOffer: String? {
            get { return self._offerDetailsWithIntroOffer }
            set { self._offerDetailsWithIntroOffer = newValue }
        }
        public var offerName: String? {
            get { return self._offerName }
            set { self._offerName = newValue }
        }
        public var features: [Feature] {
            get { return self._features }
            set { self._features = newValue }
        }

        public init(
            title: String,
            subtitle: String? = nil,
            callToAction: String,
            callToActionWithIntroOffer: String? = nil,
            offerDetails: String?,
            offerDetailsWithIntroOffer: String? = nil,
            offerName: String? = nil,
            features: [Feature] = []
        ) {
            self.title = title
            self._subtitle = subtitle
            self.callToAction = callToAction
            self._callToActionWithIntroOffer = callToActionWithIntroOffer
            self._offerDetails = offerDetails
            self._offerDetailsWithIntroOffer = offerDetailsWithIntroOffer
            self._offerName = offerName
            self.features = features
        }

        // swiftlint:enable missing_docs
    }

    /// - Returns: ``PaywallData/LocalizedConfiguration-swift.struct`` for the given `Locale`, if found.
    /// - Note: this allows searching by `Locale` with only language code and missing region (like `en`, `es`, etc).
    public func config(for requiredLocale: Locale) -> LocalizedConfiguration? {
        self.localization[requiredLocale.identifier] ??
        self.localization.first { locale, _ in
            Locale(identifier: locale).sharesLanguageCode(with: requiredLocale)
        }?.value
    }

}

extension PaywallData.LocalizedConfiguration {

    /// An item to be showcased in a paywall.
    public struct Feature {

        /// The title of the feature.
        public var title: String
        /// An optional description of the feature.
        public var content: String?
        /// An optional icon for the feature.
        /// This must be an icon identifier known by `RevenueCatUI`.
        public var iconID: String?

        // swiftlint:disable:next missing_docs
        public init(title: String, content: String? = nil, iconID: String? = nil) {
            self.title = title
            self.content = content
            self.iconID = iconID
        }

    }

}

// MARK: - Configuration

extension PaywallData {

    /// Generic configuration for any paywall.
    public struct Configuration {

        /// The list of package identifiers this paywall will display
        public var packages: [String]

        /// The package to be selected by default.
        public var defaultPackage: String?

        /// The images for this template.
        public var images: Images

        /// Whether the background image will be blurred (in templates with one).
        public var blurredBackgroundImage: Bool {
            get { self._blurredBackgroundImage }
            set { self._blurredBackgroundImage = newValue }
        }

        /// Whether a restore purchases button should be displayed.
        public var displayRestorePurchases: Bool {
            get { self._displayRestorePurchases }
            set { self._displayRestorePurchases = newValue }
        }

        /// If set, the paywall will display a terms of service link.
        public var termsOfServiceURL: URL? {
            get { self._termsOfServiceURL }
            set { self._termsOfServiceURL = newValue }
        }

        /// If set, the paywall will display a privacy policy link.
        public var privacyURL: URL? {
            get { self._privacyURL }
            set { self._privacyURL = newValue }
        }

        /// The set of colors used
        public var colors: ColorInformation

        // swiftlint:disable:next missing_docs
        public init(
            packages: [String],
            defaultPackage: String? = nil,
            images: Images,
            colors: ColorInformation,
            blurredBackgroundImage: Bool = false,
            displayRestorePurchases: Bool = true,
            termsOfServiceURL: URL? = nil,
            privacyURL: URL? = nil
        ) {
            self.packages = packages
            self.defaultPackage = defaultPackage
            self.images = images
            self.colors = colors
            self._blurredBackgroundImage = blurredBackgroundImage
            self._displayRestorePurchases = displayRestorePurchases
            self._termsOfServiceURL = termsOfServiceURL
            self._privacyURL = privacyURL
        }

        @DefaultDecodable.False
        var _blurredBackgroundImage: Bool

        @DefaultDecodable.True
        var _displayRestorePurchases: Bool

        @IgnoreDecodeErrors<URL?>
        var _termsOfServiceURL: URL?

        @IgnoreDecodeErrors<URL?>
        var _privacyURL: URL?

    }

}

extension PaywallData.Configuration {

    /// Set of images that can be used by a template.
    public struct Images {

        /// Image displayed as a header in a template.
        public var header: String? {
            get { self._header }
            set { self._header = newValue }
        }

        /// Image displayed as a background in a template.
        public var background: String? {
            get { self._background }
            set { self._background = newValue }
        }

        /// Image displayed as an app icon in a template.
        public var icon: String? {
            get { self._icon }
            set { self._icon = newValue }
        }

        @NonEmptyStringDecodable
        var _header: String?
        @NonEmptyStringDecodable
        var _background: String?
        @NonEmptyStringDecodable
        var _icon: String?

        // swiftlint:disable:next missing_docs
        public init(header: String? = nil, background: String? = nil, icon: String? = nil) {
            self.header = header
            self.background = background
            self.icon = icon
        }

    }

}

extension PaywallData.Configuration {

    /// The set of colors for all ``PaywallColor/ColorScheme``s.
    public struct ColorInformation {

        /// Set of colors for ``PaywallColor/ColorScheme/light``.
        public var light: Colors
        /// Set of colors for ``PaywallColor/ColorScheme/dark``.
        public var dark: Colors?

        // swiftlint:disable:next missing_docs
        public init(
            light: PaywallData.Configuration.Colors,
            dark: PaywallData.Configuration.Colors? = nil
        ) {
            self.light = light
            self.dark = dark
        }

    }

    /// The list of colors for a given appearance (light / dark).
    public struct Colors {

        /// Color for the background of the paywall.
        public var background: PaywallColor
        /// Color for primary text element.
        public var text1: PaywallColor
        /// Color for secondary text element.
        public var text2: PaywallColor?
        /// Color for tertiary text element.
        public var text3: PaywallColor?
        /// Background color of the main call to action button.
        public var callToActionBackground: PaywallColor
        /// Foreground color of the main call to action button.
        public var callToActionForeground: PaywallColor
        /// If present, the CTA will create a vertical gradient from ``callToActionBackground`` to this color.
        public var callToActionSecondaryBackground: PaywallColor?
        /// Primary accent color.
        public var accent1: PaywallColor?
        /// Secondary accent color
        public var accent2: PaywallColor?
        /// Tertiary accent color
        public var accent3: PaywallColor?

        // swiftlint:disable:next missing_docs
        public init(
            background: PaywallColor,
            text1: PaywallColor,
            text2: PaywallColor? = nil,
            text3: PaywallColor? = nil,
            callToActionBackground: PaywallColor,
            callToActionForeground: PaywallColor,
            callToActionSecondaryBackground: PaywallColor? = nil,
            accent1: PaywallColor? = nil,
            accent2: PaywallColor? = nil,
            accent3: PaywallColor? = nil
        ) {
            self.background = background
            self.text1 = text1
            self.text2 = text2
            self.text3 = text3
            self.callToActionBackground = callToActionBackground
            self.callToActionForeground = callToActionForeground
            self.callToActionSecondaryBackground = callToActionSecondaryBackground
            self.accent1 = accent1
            self.accent2 = accent2
            self.accent3 = accent3
        }
    }

}

// MARK: - Constructors

extension PaywallData {

    init(
        templateName: String,
        config: Configuration,
        localization: [String: LocalizedConfiguration],
        assetBaseURL: URL,
        revision: Int = 0
    ) {
        self.templateName = templateName
        self.config = config
        self.localization = localization
        self.assetBaseURL = assetBaseURL
        self.revision = revision
    }

    /// Creates a test ``PaywallData`` with one localization
    public init(
        templateName: String,
        config: Configuration,
        localization: LocalizedConfiguration,
        assetBaseURL: URL,
        revision: Int = 0
    ) {
        let locale = Locale.current.identifier

        self.init(
            templateName: templateName,
            config: config,
            localization: [locale: localization],
            assetBaseURL: assetBaseURL,
            revision: revision
        )
    }

}

// MARK: - Codable

extension PaywallData.LocalizedConfiguration.Feature: Codable {

    private enum CodingKeys: String, CodingKey {
        case title
        case content
        case iconID = "iconId"
    }

}

extension PaywallData.LocalizedConfiguration: Codable {

    private enum CodingKeys: String, CodingKey {
        case title
        case _subtitle = "subtitle"
        case callToAction
        case _callToActionWithIntroOffer = "callToActionWithIntroOffer"
        case _offerDetails = "offerDetails"
        case _offerDetailsWithIntroOffer = "offerDetailsWithIntroOffer"
        case _offerName = "offerName"
        case _features = "features"
    }

}

extension PaywallData.Configuration.ColorInformation: Codable {}
extension PaywallData.Configuration.Colors: Codable {}

extension PaywallData.Configuration.Images: Codable {

    private enum CodingKeys: String, CodingKey {
        case _header = "header"
        case _background = "background"
        case _icon = "icon"
    }

}

extension PaywallData.Configuration: Codable {

    private enum CodingKeys: String, CodingKey {
        case packages
        case defaultPackage
        case images
        case _blurredBackgroundImage = "blurredBackgroundImage"
        case _displayRestorePurchases = "displayRestorePurchases"
        case _termsOfServiceURL = "tosUrl"
        case _privacyURL = "privacyUrl"
        case colors
    }

}

extension PaywallData: Codable {

    // Note: these are camel case but converted by the decoder
    private enum CodingKeys: String, CodingKey {
        case templateName
        case config
        case localization = "localizedStrings"
        case assetBaseURL = "assetBaseUrl"
        case _revision = "revision"
    }

}

// MARK: - Equatable

extension PaywallData.LocalizedConfiguration.Feature: Hashable {}
extension PaywallData.LocalizedConfiguration: Hashable {}
extension PaywallData.Configuration.ColorInformation: Hashable {}
extension PaywallData.Configuration.Colors: Hashable {}
extension PaywallData.Configuration.Images: Hashable {}
extension PaywallData.Configuration: Hashable {}
extension PaywallData: Hashable {}

// MARK: - Sendable

extension PaywallData.LocalizedConfiguration.Feature: Sendable {}
extension PaywallData.LocalizedConfiguration: Sendable {}
extension PaywallData.Configuration.ColorInformation: Sendable {}
extension PaywallData.Configuration.Colors: Sendable {}
extension PaywallData.Configuration.Images: Sendable {}
extension PaywallData.Configuration: Sendable {}

extension PaywallData: Sendable {}

// MARK: - Extensions

private extension Locale {

    func sharesLanguageCode(with other: Locale) -> Bool {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.language.languageCode == other.language.languageCode
        } else {
            return self.languageCode == other.languageCode
        }
    }

}
