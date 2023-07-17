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
    let template: PaywallTemplate = data.template
    let config: PaywallData.Configuration = data.config
    let locale: Locale = data.defaultLocale
    let _: PaywallData.LocalizedConfiguration? = data.config(for: locale)
    let localization: PaywallData.LocalizedConfiguration = data.localizedConfiguration
    let assetBaseURL: URL = data.assetBaseURL

    let _: PaywallData = .init(template: template,
                               config: config,
                               localization: localization,
                               assetBaseURL: assetBaseURL)
}

func checkPaywallConfiguration(_ config: PaywallData.Configuration,
                               _ colors: PaywallData.Configuration.ColorInformation) {
    let _: PaywallData.Configuration = .init(packages: [.monthly, .annual], headerImageName: "", colors: colors)
    let _: [PackageType] = config.packages
    let _: String = config.headerImageName
}

func checkPaywallLocalizedConfig(_ config: PaywallData.LocalizedConfiguration) {
    let title: String = config.title
    let subtitle: String = config.subtitle
    let callToAction: String = config.callToAction
    let callToActionWithIntroOffer: String? = config.callToActionWithIntroOffer
    let offerDetails: String = config.offerDetails
    let offerDetailsWithIntroOffer: String? = config.offerDetailsWithIntroOffer

    let _: PaywallData.LocalizedConfiguration = .init(
        title: title,
        subtitle: subtitle,
        callToAction: callToAction,
        callToActionWithIntroOffer: callToActionWithIntroOffer,
        offerDetails: offerDetails,
        offerDetailsWithIntroOffer: offerDetailsWithIntroOffer
    )
}

func checkPaywallColors(_ config: PaywallData.Configuration.Colors) {
    let background: PaywallColor = config.background
    let foreground: PaywallColor = config.foreground
    let callToActionBackground: PaywallColor = config.callToActionBackground
    let callToActionForeground: PaywallColor = config.callToActionForeground

    _ = PaywallData.Configuration.Colors(
        background: background,
        foreground: foreground,
        callToActionBackground: callToActionBackground,
        callToActionForeground: callToActionForeground
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

    #if canImport(SwiftUI) && swift(>=5.7)
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
        _ = PaywallColor(light: color, dark: color)
    }
    #endif

    let _: String = color.debugDescription
    let _: String = color.stringRepresentation
    #if canImport(SwiftUI) && swift(>=5.7)
    if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
        let _: Color = color.underlyingColor
    }
    #endif
}

func checkPaywallTemplate(_ template: PaywallTemplate) {
    switch template {
    case .example1:
        break
    @unknown default:
        break
    }
}
