//
//  PaywallAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 7/11/23.
//

import Foundation
import RevenueCat

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

func checkPaywallConfiguration(_ config: PaywallData.Configuration) {
    let _: PaywallData.Configuration = .init(packages: [.monthly, .annual], headerImageName: "")
    let _: [PackageType] = config.packages
    let _: String = config.headerImageName
}

func checkPaywallLocalizedConfig(_ config: PaywallData.LocalizedConfiguration) {
    let title: String = config.title
    let subtitle: String = config.subtitle
    let callToAction: String = config.callToAction
    let callToActionWithIntroOffer: String = config.callToActionWithIntroOffer
    let offerDetails: String = config.offerDetails
    let offerDetailsWithIntroOffer: String = config.offerDetailsWithIntroOffer

    let _: PaywallData.LocalizedConfiguration = .init(
        title: title,
        subtitle: subtitle,
        callToAction: callToAction,
        callToActionWithIntroOffer: callToActionWithIntroOffer,
        offerDetails: offerDetails,
        offerDetailsWithIntroOffer: offerDetailsWithIntroOffer
    )
}

func checkPaywallTemplate(_ template: PaywallTemplate) {
    switch template {
    case .example1:
        break
    @unknown default:
        break
    }
}
