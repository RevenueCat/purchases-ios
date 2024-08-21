//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallDataMultiTierTests.swift
//
//  Created by Nacho Soto on 2/7/24.

import Foundation

import Nimble
@testable import RevenueCat
import XCTest

class PaywallDataMultiTierTests: BaseHTTPResponseTest {

    private var paywall: PaywallData!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.paywall = try self.decodeFixture("PaywallData-multitier1")
    }

    func testConfiguration() throws {
        expect(self.paywall.templateName) == "7"
        expect(self.paywall.assetBaseURL) == URL(string: "https://rc-paywalls.s3.amazonaws.com")!
        expect(self.paywall.revision) == 7
        expect(self.paywall.config.packages).to(beEmpty())
        expect(self.paywall.config.defaultPackage).to(beNil())
        expect(self.paywall.config.images) == .init(
            header: nil,
            background: nil,
            icon: nil
        )
        expect(self.paywall.config.blurredBackgroundImage) == false
        expect(self.paywall.config.displayRestorePurchases) == true
        expect(self.paywall.config.termsOfServiceURL) == URL(string: "https://revenuecat.com/tos")!
        expect(self.paywall.config.privacyURL) == URL(string: "https://revenuecat.com/privacy")!
        expect(self.paywall.localization).to(beEmpty())
    }

    func testTiers() throws {
        let tiers = self.paywall.config.tiers
        expect(tiers).to(haveCount(2))
        let (standard, premium) = (tiers[0], tiers[1])

        expect(standard) == .init(
            id: "standard",
            packages: ["standard_annual", "standard_monthly"],
            defaultPackage: "standard_annual"
        )
        expect(premium) == .init(
            id: "premium",
            packages: ["premium_annual", "premium_monthly"],
            defaultPackage: "premium_monthly"
        )
    }

    func testLocalization() throws {
        let english = try XCTUnwrap(self.paywall.localizationByTier["en_US"])
        let spanish = try XCTUnwrap(self.paywall.localizationByTier["es_ES"])

        expect(english).to(haveCount(self.paywall.config.tiers.count))
        expect(spanish).to(haveCount(self.paywall.config.tiers.count))

        expect(english["standard"]) == .init(
            title: "Get started with our Standard plan",
            callToAction: "{{ price_per_period_full }}",
            callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free trial",
            features: [
                .init(
                    title: "Access to 30 cinematic LUTs",
                    iconID: "tick"
                ),
                .init(
                    title: "Pro fonts and transition effects",
                    iconID: "tick"
                ),
                .init(
                    title: "10+ templates",
                    iconID: "tick"
                )
            ],
            tierName: "Standard"
        )
        expect(english["premium"]) == .init(
            title: "Master the art of video editing",
            callToAction: "{{ price_per_period_full }}",
            callToActionWithIntroOffer: "Start your {{ sub_offer_duration }} free trial",
            features: [
                .init(
                    title: "Access to all 150 of our cinematic LUTs",
                    iconID: "tick"
                ),
                .init(
                    title: "Custom design tools and transition effects",
                    iconID: "tick"
                ),
                .init(
                    title: "100+ exclusive templates",
                    iconID: "tick"
                )
            ],
            tierName: "Premium"
        )
        expect(spanish["standard"]) == .init(
            title: "Comienza con nuestro plan Estándar",
            callToAction: "{{ price_per_period_full }}",
            callToActionWithIntroOffer: "Inicia tu prueba de {{ sub_offer_duration }}",
            features: [
                .init(
                    title: "Acceso a 30 LUTs cinematográficos",
                    iconID: "tick"
                ),
                .init(
                    title: "Fuentes Pro y efectos de transición",
                    iconID: "tick"
                ),
                .init(
                    title: "Más de 10 plantillas",
                    iconID: "tick"
                )
            ],
            tierName: "Estándar"
        )
        expect(spanish["premium"]) == .init(
            title: "Domina el arte de la edición de video",
            callToAction: "{{ price_per_period_full }}",
            callToActionWithIntroOffer: "Inicia tu prueba de {{ sub_offer_duration }}",
            features: [
                .init(
                    title: "Acceso a todos nuestros 150 LUTs cinematográficos",
                    iconID: "tick"
                ),
                .init(
                    title: "Herramientas de diseño personalizado y efectos de transición",
                    iconID: "tick"
                ),
                .init(
                    title: "Más de 100 plantillas exclusivas",
                    iconID: "tick"
                )
            ],
            tierName: "Premium"
        )
    }

    func testImages() throws {
        let images = self.paywall.config.imagesByTier
        expect(images) == [
            "standard": .init(
                header: "954459_1703109702.png"
            ),
            "premium": .init(
                header: "header.heic"
            )
        ]
    }

    func testColors() throws {
        let standardColors = try XCTUnwrap(self.paywall.config.colorsByTier["standard"])
        let premiumColors = try XCTUnwrap(self.paywall.config.colorsByTier["premium"])

        expect(standardColors.light.background?.stringRepresentation) == "#FFFFFF"
        expect(standardColors.light.text1?.stringRepresentation) == "#000000"
        expect(standardColors.light.text2?.stringRepresentation) == "#FFFFFF"
        expect(standardColors.light.text3?.stringRepresentation) == "#000000"
        expect(standardColors.light.callToActionBackground?.stringRepresentation) == "#00FF00"
        expect(standardColors.light.callToActionForeground?.stringRepresentation) == "#FFFFFF"
        expect(standardColors.light.callToActionSecondaryBackground).to(beNil())
        expect(standardColors.light.accent1?.stringRepresentation) == "#f25a5a"
        expect(standardColors.light.accent2?.stringRepresentation) == "#f25a5a"
        expect(standardColors.light.accent3?.stringRepresentation) == "#DFDFDF"

        expect(standardColors.dark?.background?.stringRepresentation) == "#000000"
        expect(standardColors.dark?.text1?.stringRepresentation) == "#FFFFFF"
        expect(standardColors.dark?.text2?.stringRepresentation) == "#000000"
        expect(standardColors.dark?.text3?.stringRepresentation) == "#FFFFFF"
        expect(standardColors.dark?.callToActionBackground?.stringRepresentation) == "#f25a5a"
        expect(standardColors.dark?.callToActionForeground?.stringRepresentation) == "#0000FF"
        expect(standardColors.dark?.callToActionSecondaryBackground).to(beNil())
        expect(standardColors.dark?.accent1?.stringRepresentation) == "#f25a5a"
        expect(standardColors.dark?.accent2?.stringRepresentation) == "#f25a5a"
        expect(standardColors.dark?.accent3?.stringRepresentation) == "#606463"

        expect(premiumColors.light.background?.stringRepresentation) == "#FFFFFF"
        expect(premiumColors.light.text1?.stringRepresentation) == "#000000"
        expect(premiumColors.light.text2?.stringRepresentation) == "#FFFFFF"
        expect(premiumColors.light.text3?.stringRepresentation) == "#000000"
        expect(premiumColors.light.callToActionBackground?.stringRepresentation) == "#f25a5a"
        expect(premiumColors.light.callToActionForeground?.stringRepresentation) == "#FFFFFF"
        expect(premiumColors.light.callToActionSecondaryBackground).to(beNil())
        expect(premiumColors.light.accent1?.stringRepresentation) == "#FF0000"
        expect(premiumColors.light.accent2?.stringRepresentation) == "#f25a5a"
        expect(premiumColors.light.accent3?.stringRepresentation) == "#DFDFDF"

        expect(premiumColors.dark?.background?.stringRepresentation) == "#000000"
        expect(premiumColors.dark?.text1?.stringRepresentation) == "#FFFFFF"
        expect(premiumColors.dark?.text2?.stringRepresentation) == "#000000"
        expect(premiumColors.dark?.text3?.stringRepresentation) == "#FFFFFF"
        expect(premiumColors.dark?.callToActionBackground?.stringRepresentation) == "#f25a5a"
        expect(premiumColors.dark?.callToActionForeground?.stringRepresentation) == "#FFFFFF"
        expect(premiumColors.dark?.callToActionSecondaryBackground).to(beNil())
        expect(premiumColors.dark?.accent1?.stringRepresentation) == "#f25a5a"
        expect(premiumColors.dark?.accent2?.stringRepresentation) == "#00FFFF"
        expect(premiumColors.dark?.accent3?.stringRepresentation) == "#606463"
    }

    func testConfigForLocale() throws {
        let localization = try XCTUnwrap(self.paywall.tiersLocalization(for: .init(identifier: "en_US")))
        expect(Set(localization.keys)) == ["standard", "premium"]
    }

    func testEnglishLocalizedConfiguration() throws {
        let (_, localization) = try XCTUnwrap(self.paywall.localizedConfigurationByTier(for: [
            .init(identifier: "en_UK"),
            .init(identifier: "es_ES")
        ]))

        expect(Set(localization.keys)) == ["standard", "premium"]
        expect(localization["standard"]?.tierName) == "Standard"
        expect(localization["premium"]?.tierName) == "Premium"
    }

    func testSpanishLocalizedConfiguration() throws {
        let (_, localization) = try XCTUnwrap(self.paywall.localizedConfigurationByTier(for: [
            .init(identifier: "es_ES"),
            .init(identifier: "en_UK")
        ]))

        expect(Set(localization.keys)) == ["standard", "premium"]
        expect(localization["standard"]?.tierName) == "Estándar"
        expect(localization["premium"]?.tierName) == "Premium"
    }

}
