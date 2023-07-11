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

    let _: PaywallData = .init(template: template,
                               config: config,
                               localization: localization)
}

func checkPaywallConfiguration(_ config: PaywallData.Configuration) {
    let _: PaywallData.Configuration = .init()
}

func checkPaywallLocalizedConfig(_ config: PaywallData.LocalizedConfiguration) {
    let _: String = config.callToAction
    let _: String = config.title
}

func checkPaywallTemplate(_ template: PaywallTemplate) {
    switch template {
    case .example1:
        break
    @unknown default:
        break
    }
}
