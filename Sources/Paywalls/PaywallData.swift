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

    /// The storefront country codes that should not display cents in prices.
    public var zeroDecimalPlaceCountries: [String] {
        _zeroDecimalPlaceCountries?.apple ?? []
    }

    internal private(set) var _zeroDecimalPlaceCountries: ZeroDecimalPlaceCountries?

    /// The default locale identifier for this paywall.
    public var defaultLocale: String?

    @DefaultDecodable.Zero
    internal private(set) var _revision: Int = 0

    @DefaultDecodable.EmptyDictionary
    internal private(set) var localization: [String: LocalizedConfiguration]

    @DefaultDecodable.EmptyDictionary
    internal private(set) var localizationByTier: [String: [String: LocalizedConfiguration]]

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
    /// An optional name representing the ``PaywallData/Tier``.
    var tierName: String? { get }

}

extension PaywallData {
    /// Represents countries where currencies typically have zero decimal places
    public struct ZeroDecimalPlaceCountries: Codable, Sendable, Hashable, Equatable {

        /// Storefront country codes that should typically display zero decimal places
        public var apple: [String] = []

        /// Storefront country codes that should typically display zero decimal places.
        public init(apple: [String]) {
            self.apple = apple
        }

    }
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
        @NonEmptyStringDecodable
        var _tierName: String?
        @DefaultDecodable.EmptyDictionary
        var _offerOverrides: [String: OfferOverride]

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
        public var offerOverrides: [String: OfferOverride] {
            get { return self._offerOverrides }
            set { self._offerOverrides = newValue }
        }
        public var features: [Feature] {
            get { return self._features }
            set { self._features = newValue }
        }
        public var tierName: String? {
            get { return self._tierName }
            set { self._tierName = newValue }
        }

        public init(
            title: String,
            subtitle: String? = nil,
            callToAction: String,
            callToActionWithIntroOffer: String? = nil,
            offerDetails: String? = nil,
            offerDetailsWithIntroOffer: String? = nil,
            offerName: String? = nil,
            offerOverrides: [String: OfferOverride] = [:],
            features: [Feature] = [],
            tierName: String? = nil
        ) {
            self.title = title
            self._subtitle = subtitle
            self.callToAction = callToAction
            self._callToActionWithIntroOffer = callToActionWithIntroOffer
            self._offerDetails = offerDetails
            self._offerDetailsWithIntroOffer = offerDetailsWithIntroOffer
            self._offerName = offerName
            self._offerOverrides = offerOverrides
            self.features = features
            self._tierName = tierName
        }

        // swiftlint:enable missing_docs
    }

    /// - Returns: ``PaywallData/LocalizedConfiguration-swift.struct`` for the given `Locale`, if found.
    /// - Note: this allows searching by `Locale` with only language code and missing region (like `en`, `es`, etc).
    public func config(for requiredLocale: Locale) -> LocalizedConfiguration? {
        return Self.config(for: requiredLocale, localizationByLocale: self.localization)
    }

    /// - Returns: ``PaywallData/LocalizedConfiguration-swift.struct`` for all tiers,
    /// for the given `Locale`, if found.
    /// - Note: this allows searching by `Locale` with only language code and missing region (like `en`, `es`, etc).
    public func tiersLocalization(for requiredLocale: Locale) -> [String: LocalizedConfiguration]? {
        return Self.config(for: requiredLocale, localizationByLocale: self.localizationByTier)
    }

    internal static func config<Value>(
        for requiredLocale: Locale,
        localizationByLocale: [String: Value]
    ) -> Value? {
        localizationByLocale[requiredLocale.identifier] ??
        localizationByLocale.first { locale, _ in
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

extension PaywallData.LocalizedConfiguration {

    /// Custom displayable overrides for a package 
    public struct OfferOverride {

        /// Description for the offer to be purchased.
        public var offerDetails: String?
        /// Description for the offer to be purchased when an intro offer is available.
        /// If `nil`, no information regarding trial eligibility will be displayed.
        public var offerDetailsWithIntroOffer: String?
        /// The name representing each of the packages, most commonly a variable.
        public var offerName: String?
        /// An optional string to put in a badge on the package.
        public var offerBadge: String?

        // swiftlint:disable:next missing_docs
        public init(
            offerDetails: String? = nil,
            offerDetailsWithIntroOffer: String? = nil,
            offerName: String? = nil,
            offerBadge: String? = nil
        ) {
            self.offerDetails = offerDetails
            self.offerDetailsWithIntroOffer = offerDetailsWithIntroOffer
            self.offerName = offerName
            self.offerBadge = offerBadge
        }

    }

}

// MARK: - Configuration

extension PaywallData {

    /// Generic configuration for any paywall.
    public struct Configuration {

        /// The list of package identifiers this paywall will display
        public var packages: [String] {
            get { self._packages }
            set { self._packages = newValue }
        }

        /// The package to be selected by default.
        public var defaultPackage: String?

        /// The ordered list of tiers in this paywall.
        public var tiers: [Tier] {
            get { self._tiers }
            set { self._tiers = newValue }
        }

        /// The images for this template.
        public var images: Images {
            get {
                return Self.merge(source: self._imagesHeic, fallback: self._legacyImages)
            }

            set {
                self._imagesHeic = newValue
                self._legacyImages = nil
            }
        }

        /// The images for each of the tiers.
        public internal(set) var imagesByTier: [String: Images] {
            get { self._imagesByTier }
            set { self._imagesByTier = newValue }
        }

        /// Low resolution images for this template.
        public var imagesLowRes: Images {
            get { self._imagesHeicLowRes ?? Images() }
            set { self._imagesHeicLowRes = newValue }
        }

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

        /// The set of colors used.
        public var colors: ColorInformation

        /// The set of colors for each of the tiers.
        public var colorsByTier: [String: ColorInformation] {
            get { self._colorsByTier }
            set { self._colorsByTier = newValue }
        }

        /// Creates a single-tier ``PaywallData/Configuration``.
        public init(
            packages: [String],
            defaultPackage: String? = nil,
            images: Images,
            imagesLowRes: Images = Images(),
            colors: ColorInformation,
            blurredBackgroundImage: Bool = false,
            displayRestorePurchases: Bool = true,
            termsOfServiceURL: URL? = nil,
            privacyURL: URL? = nil
        ) {
            self._packages = packages
            self.defaultPackage = defaultPackage
            self._imagesHeic = images
            self._imagesHeicLowRes = imagesLowRes
            self.colors = colors
            self._blurredBackgroundImage = blurredBackgroundImage
            self._displayRestorePurchases = displayRestorePurchases
            self._termsOfServiceURL = termsOfServiceURL
            self._privacyURL = privacyURL
        }

        /// Creates a multi-tier ``PaywallData/Configuration``.
        public init(
            images: Images,
            imagesByTier: [String: Images] = [:],
            colors: ColorInformation,
            colorsByTier: [String: ColorInformation] = [:],
            tiers: [Tier],
            blurredBackgroundImage: Bool = false,
            displayRestorePurchases: Bool = true,
            termsOfServiceURL: URL? = nil,
            privacyURL: URL? = nil
        ) {
            self._packages = []
            self.defaultPackage = nil
            self._imagesHeic = images
            self._imagesByTier = imagesByTier
            self.colors = colors
            self._colorsByTier = colorsByTier
            self._tiers = tiers
            self._blurredBackgroundImage = blurredBackgroundImage
            self._displayRestorePurchases = displayRestorePurchases
            self._termsOfServiceURL = termsOfServiceURL
            self._privacyURL = privacyURL
        }

        @DefaultDecodable.EmptyArray
        var _packages: [String]

        var _legacyImages: Images?
        var _imagesHeic: Images?
        var _imagesHeicLowRes: Images?

        @DefaultDecodable.EmptyArray
        var _tiers: [Tier]

        @DefaultDecodable.False
        var _blurredBackgroundImage: Bool

        @DefaultDecodable.True
        var _displayRestorePurchases: Bool

        @IgnoreDecodeErrors<URL?>
        var _termsOfServiceURL: URL?

        @IgnoreDecodeErrors<URL?>
        var _privacyURL: URL?

        @DefaultDecodable.EmptyDictionary
        var _colorsByTier: [String: ColorInformation]

        @DefaultDecodable.EmptyDictionary
        var _imagesByTier: [String: Images]

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

    fileprivate static func merge(source: Images?, fallback: Images?) -> Images {
        return .init(
            header: source?.header ?? fallback?.header,
            background: source?.background ?? fallback?.background,
            icon: source?.icon ?? fallback?.icon
        )
    }

    fileprivate static func merge(source: ColorInformation, override: ColorInformation?) -> ColorInformation {
        return .init(
            light: Self.merge(source: source.light, override: override?.light),
            dark: source.dark.map { Self.merge(source: $0, override: override?.dark) }
        )
    }

    fileprivate static func merge(source: Colors, override: Colors?) -> Colors {
        var result = source

        for property in Colors.properties {
            if let override = override?[keyPath: property] {
                result[keyPath: property] = override
            }
        }

        return result
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
        public var background: PaywallColor?
        /// Color for primary text element.
        public var text1: PaywallColor?
        /// Color for secondary text element.
        public var text2: PaywallColor?
        /// Color for tertiary text element.
        public var text3: PaywallColor?
        /// Background color of the main call to action button.
        public var callToActionBackground: PaywallColor?
        /// Foreground color of the main call to action button.
        public var callToActionForeground: PaywallColor?
        /// If present, the CTA will create a vertical gradient from ``callToActionBackground`` to this color.
        public var callToActionSecondaryBackground: PaywallColor?
        /// Primary accent color.
        public var accent1: PaywallColor?
        /// Secondary accent color
        public var accent2: PaywallColor?
        /// Tertiary accent color
        public var accent3: PaywallColor?
        /// Color for the close button of the paywall.
        public var closeButton: PaywallColor?
        /// Color for the tier selector background color.
        public var tierControlBackground: PaywallColor?
        /// Color for the tier selector foreground color.
        public var tierControlForeground: PaywallColor?
        /// Color for the tier selector background color for selected tier.
        public var tierControlSelectedBackground: PaywallColor?
        /// Color for the tier selector foreground color for selected tier.
        public var tierControlSelectedForeground: PaywallColor?

        // swiftlint:disable:next missing_docs
        public init(
            background: PaywallColor? = nil,
            text1: PaywallColor? = nil,
            text2: PaywallColor? = nil,
            text3: PaywallColor? = nil,
            callToActionBackground: PaywallColor? = nil,
            callToActionForeground: PaywallColor? = nil,
            callToActionSecondaryBackground: PaywallColor? = nil,
            accent1: PaywallColor? = nil,
            accent2: PaywallColor? = nil,
            accent3: PaywallColor? = nil,
            closeButton: PaywallColor? = nil,
            tierControlBackground: PaywallColor? = nil,
            tierControlForeground: PaywallColor? = nil,
            tierControlSelectedBackground: PaywallColor? = nil,
            tierControlSelectedForeground: PaywallColor? = nil
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
            self.closeButton = closeButton
            self.tierControlBackground = tierControlBackground
            self.tierControlForeground = tierControlForeground
            self.tierControlSelectedBackground = tierControlSelectedBackground
            self.tierControlSelectedForeground = tierControlSelectedForeground
        }
    }

}

// MARK: - Tiers

extension PaywallData {

    /// A group of packages that can be displayed together in a multi-tier paywall template.
    public struct Tier {

        /// The identifier for this tier.
        public var id: String

        /// The list of package identifiers this tier will display
        public var packages: [String]

        /// The package to be selected by default.
        public var defaultPackage: String

        // swiftlint:disable:next missing_docs
        public init(id: String, packages: [String], defaultPackage: String) {
            self.id = id
            self.packages = packages
            self.defaultPackage = defaultPackage
        }

    }

}

// MARK: - Constructors

extension PaywallData {
    init(
        templateName: String,
        config: Configuration,
        localization: [String: LocalizedConfiguration],
        localizationByTier: [String: [String: LocalizedConfiguration]],
        assetBaseURL: URL,
        revision: Int = 0,
        zeroDecimalPlaceCountries: [String] = []
    ) {
        self.templateName = templateName
        self.config = config
        self.localization = localization
        self.localizationByTier = localizationByTier
        self.assetBaseURL = assetBaseURL
        self.revision = revision
        self._zeroDecimalPlaceCountries = .init(apple: zeroDecimalPlaceCountries)
    }

    /// Creates a test ``PaywallData`` with one localization.
    public init(
        templateName: String,
        config: Configuration,
        localization: LocalizedConfiguration,
        assetBaseURL: URL,
        revision: Int = 0,
        locale: Locale = .current,
        zeroDecimalPlaceCountries: [String] = []
    ) {
        self.init(
            templateName: templateName,
            config: config,
            localization: [locale.identifier: localization],
            localizationByTier: [:],
            assetBaseURL: assetBaseURL,
            revision: revision,
            zeroDecimalPlaceCountries: zeroDecimalPlaceCountries
        )
    }

    /// Creates a test multi-tier ``PaywallData`` with a single localization.
    public init(
        templateName: String,
        config: Configuration,
        localizationByTier: [String: LocalizedConfiguration],
        assetBaseURL: URL,
        revision: Int = 0,
        locale: Locale = .current,
        zeroDecimalPlaceCountries: [String] = []
    ) {
        self.init(
            templateName: templateName,
            config: config,
            localization: [:],
            localizationByTier: [locale.identifier: localizationByTier],
            assetBaseURL: assetBaseURL,
            revision: revision,
            zeroDecimalPlaceCountries: zeroDecimalPlaceCountries
        )
    }

}

// MARK: -

private extension PaywallData.Configuration.Colors {

    static let properties: Set<WritableKeyPath<Self, PaywallColor?>> = [
        \.background,
         \.text1,
         \.text2,
         \.text3,
         \.callToActionBackground,
         \.callToActionForeground,
         \.callToActionSecondaryBackground,
         \.accent1,
         \.accent2,
         \.accent3
    ]

}

// MARK: - Codable

extension PaywallData.LocalizedConfiguration.Feature: Codable {

    private enum CodingKeys: String, CodingKey {
        case title
        case content
        case iconID = "iconId"
    }

}

extension PaywallData.LocalizedConfiguration.OfferOverride: Codable {}

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
        case _tierName = "tierName"
        case _offerOverrides = "offerOverrides"
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

extension PaywallData.Tier: Codable {}

extension PaywallData.Configuration: Codable {

    private enum CodingKeys: String, CodingKey {
        case _packages = "packages"
        case defaultPackage
        case _tiers = "tiers"
        case _legacyImages = "images"
        case _imagesHeic = "imagesHeic"
        case _imagesHeicLowRes = "imagesHeicLowRes"
        case _blurredBackgroundImage = "blurredBackgroundImage"
        case _displayRestorePurchases = "displayRestorePurchases"
        case _termsOfServiceURL = "tosUrl"
        case _privacyURL = "privacyUrl"
        case colors
        case _colorsByTier = "colorsByTier"
        case _imagesByTier = "imagesByTier"
    }

}

extension PaywallData: Codable {

    // Note: these are camel case but converted by the decoder
    private enum CodingKeys: String, CodingKey {
        case templateName
        case config
        case localization = "localizedStrings"
        case localizationByTier = "localizedStringsByTier"
        case assetBaseURL = "assetBaseUrl"
        case _revision = "revision"
        case _zeroDecimalPlaceCountries = "zeroDecimalPlaceCountries"
        case defaultLocale = "defaultLocale"
    }

}

// MARK: - Equatable

extension PaywallData.Tier: Hashable {}
extension PaywallData.LocalizedConfiguration.Feature: Hashable {}
extension PaywallData.LocalizedConfiguration.OfferOverride: Hashable {}
extension PaywallData.LocalizedConfiguration: Hashable {}
extension PaywallData.Configuration.ColorInformation: Hashable {}
extension PaywallData.Configuration.Colors: Hashable {}
extension PaywallData.Configuration.Images: Hashable {}
extension PaywallData.Configuration: Hashable {}
extension PaywallData: Hashable {}

// MARK: - Sendable

extension PaywallData.LocalizedConfiguration.Feature: Sendable {}
extension PaywallData.LocalizedConfiguration.OfferOverride: Sendable {}
extension PaywallData.LocalizedConfiguration: Sendable {}
extension PaywallData.Tier: Sendable {}
extension PaywallData.Configuration.ColorInformation: Sendable {}
extension PaywallData.Configuration.Colors: Sendable {}
extension PaywallData.Configuration.Images: Sendable {}
extension PaywallData.Configuration: Sendable {}

extension PaywallData: Sendable {}

// MARK: - Identifiable

extension PaywallData.Tier: Identifiable {}

// MARK: - Extensions

private extension Locale {

    func sharesLanguageCode(with other: Locale) -> Bool {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            return self.language.isEquivalent(to: other.language)
        } else {
            return self.languageCode == other.languageCode
        }
    }

}
