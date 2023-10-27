//
//  PaywallAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 7/11/23.
//

import Foundation
import RevenueCat

#if canImport(SwiftUI)
import SwiftUI
#endif

func checkPaywallData(_ data: PaywallData) {
    let templateName: String = data.templateName
    let config: PaywallData.Configuration = data.config
    let _: PaywallData.LocalizedConfiguration? = data.config(for: Locale.current)
    let localization: PaywallData.LocalizedConfiguration = data.localizedConfiguration
    let assetBaseURL: URL = data.assetBaseURL
    let revision: Int = data.revision

    let _: PaywallData = .init(templateName: templateName,
                               config: config,
                               localization: localization,
                               assetBaseURL: assetBaseURL,
                               revision: revision)
}

func checkPaywallConfiguration(_ config: PaywallData.Configuration,
                               _ images: PaywallData.Configuration.Images,
                               _ colors: PaywallData.Configuration.ColorInformation) {
    let _: PaywallData.Configuration = .init(packages: ["$rc_monthly", "$rc_annual"],
                                             images: images,
                                             colors: colors)
    let _: PaywallData.Configuration = .init(packages: ["$rc_monthly", "custom"],
                                             defaultPackage: "custom",
                                             images: images,
                                             colors: colors,
                                             blurredBackgroundImage: true,
                                             displayRestorePurchases: true,
                                             termsOfServiceURL: URL(string: ""),
                                             privacyURL: URL(string: ""))
    let _: [String] = config.packages
    let _: String? = config.defaultPackage
    let _: PaywallData.Configuration.Images = config.images
    let _: PaywallData.Configuration.ColorInformation = config.colors
    let _: Bool = config.blurredBackgroundImage
    let _: Bool = config.displayRestorePurchases
    let _: URL? = config.termsOfServiceURL
    let _: URL? = config.privacyURL
}

func checkPaywallLocalizedConfig(_ config: PaywallData.LocalizedConfiguration) {
    let title: String = config.title
    let subtitle: String? = config.subtitle
    let callToAction: String = config.callToAction
    let callToActionWithIntroOffer: String? = config.callToActionWithIntroOffer
    let offerDetails: String? = config.offerDetails
    let offerDetailsWithIntroOffer: String? = config.offerDetailsWithIntroOffer
    let offerName: String? = config.offerName
    let features: [PaywallData.LocalizedConfiguration.Feature] = config.features

    let _: PaywallData.LocalizedConfiguration = .init(
        title: title,
        subtitle: subtitle,
        callToAction: callToAction,
        callToActionWithIntroOffer: callToActionWithIntroOffer,
        offerDetails: offerDetails,
        offerDetailsWithIntroOffer: offerDetailsWithIntroOffer,
        offerName: offerName,
        features: features
    )
}

func checkLocalizedConfigFeature(_ feature: PaywallData.LocalizedConfiguration.Feature) {
    let title: String = feature.title
    let content: String? = feature.content
    let iconID: String? = feature.iconID

    let _: PaywallData.LocalizedConfiguration.Feature = .init(title: title,
                                                              content: content,
                                                              iconID: iconID)
}

func checkPaywallImages(_ images: PaywallData.Configuration.Images) {
    let header: String? = images.header
    let background: String? = images.background
    let icon: String? = images.icon

    _ = PaywallData.Configuration.Images()

    _ = PaywallData.Configuration.Images(
        header: header,
        background: background,
        icon: icon
    )
}

func checkPaywallColors(_ config: PaywallData.Configuration.Colors) {
    let background: PaywallColor = config.background
    let text1: PaywallColor = config.text1
    let text2: PaywallColor? = config.text2
    let text3: PaywallColor? = config.text3
    let callToActionBackground: PaywallColor = config.callToActionBackground
    let callToActionForeground: PaywallColor = config.callToActionForeground
    let callToActionSecondaryBackground: PaywallColor? = config.callToActionSecondaryBackground
    let accent1: PaywallColor? = config.accent1
    let accent2: PaywallColor? = config.accent2
    let accent3: PaywallColor? = config.accent3

    _ = PaywallData.Configuration.Colors(
        background: background,
        text1: text1,
        text2: text2,
        text3: text3,
        callToActionBackground: callToActionBackground,
        callToActionForeground: callToActionForeground,
        callToActionSecondaryBackground: callToActionSecondaryBackground,
        accent1: accent1,
        accent2: accent2,
        accent3: accent3
    )
}

func checkPaywallColorInformation(_ config: PaywallData.Configuration.ColorInformation) {
    let light: PaywallData.Configuration.Colors = config.light
    let dark: PaywallData.Configuration.Colors? = config.dark

    _ = PaywallData.Configuration.ColorInformation(
        light: light,
        dark: dark
    )
}

func checkPaywallColor(_ color: PaywallColor) throws {
    _ = try PaywallColor(stringRepresentation: "")

    #if canImport(UIKit) && !os(watchOS)
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
        _ = PaywallColor(light: color, dark: color)
    }
    #endif

    let _: String = color.debugDescription
    let _: String = color.stringRepresentation
    #if canImport(SwiftUI)
    if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
        let _: Color = color.underlyingColor
    }
    #endif
}

#if canImport(SwiftUI) && canImport(UIKit) && !os(watchOS)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, *)
func checkConversions(color: Color, uiColor: UIColor) {
    let _: PaywallColor = color.asPaywallColor

    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, *) {
        let _: PaywallColor = uiColor.asPaywallColor
    }
}

#endif

func checkPaywallViewMode(_ mode: PaywallViewMode) {
    switch mode {
    case .fullScreen:
        break
    case .footer:
        break
    case .condensedFooter:
        break
    @unknown default:
        break
    }
}

func checkPaywallEvent(_ event: PaywallEvent) {
    let _: PaywallEvent.SessionID = UUID()

    switch event {
    case let .impression(creationData, data):
        checkPaywallEventCreationData(creationData)
        checkPaywallEventData(data)
    case let .cancel(creationData, data):
        checkPaywallEventCreationData(creationData)
        checkPaywallEventData(data)
    case let .close(creationData, data):
        checkPaywallEventCreationData(creationData)
        checkPaywallEventData(data)
    @unknown default: break
    }

    let _: PaywallEvent.Data = event.data
}

func checkPaywallEventCreationData(_ creationData: PaywallEvent.CreationData) {
    let _: PaywallEvent.ID = creationData.id
    let _: Date = creationData.date

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func create(
        id: PaywallEvent.ID,
        date: Date
    ) {
        _ = PaywallEvent.CreationData.init(
            id: id,
            date: date
        )
    }
}

func checkPaywallEventData(_ data: PaywallEvent.Data) {
    let _: String = data.offeringIdentifier
    let _: Int = data.paywallRevision
    let _: PaywallEvent.SessionID = data.sessionIdentifier
    let _: PaywallViewMode = data.displayMode
    let _: String = data.localeIdentifier
    let _: Bool = data.darkMode

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func create(
        offering: Offering,
        paywall: PaywallData,
        sessionID: PaywallEvent.SessionID,
        displayMode: PaywallViewMode,
        locale: Locale,
        darkMode: Bool
    ) {
        _ = PaywallEvent.Data.init(
            offering: offering,
            paywall: paywall,
            sessionID: sessionID,
            displayMode: displayMode,
            locale: locale,
            darkMode: darkMode
        )
    }
}
