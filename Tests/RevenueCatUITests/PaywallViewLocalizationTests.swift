//
//  PaywallViewLocalizationTests.swift
//
//
//  Created by Nacho Soto on 7/17/23.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SnapshotTesting
import SwiftUI

 @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
 class PaywallViewLocalizationTests: BaseSnapshotTest {

    func testSpanish() {
        Self.test(.init(identifier: "es_ES"))
    }

 }

 @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
 private extension PaywallViewLocalizationTests {

    static func test(_ locale: Locale) {
        Self.createView()
            .environment(\.locale, locale)
            .snapshot(size: Self.fullScreenSize)
    }

    private static func createView() -> some View {
        return PaywallView(
            offering: Self.offering,
            paywall: Self.offering.paywallWithLocalImages,
            introEligibility: .init(checker: { product in
                return product.subscriptionPeriod?.unit == .month
                    ? .eligible
                    : .ineligible
            }),
            purchaseHandler: Self.purchaseHandler
        )
    }

     private static let offering = Offering(
        identifier: "offering",
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
            template: .multiPackage,
            config: .init(
                packages: [.weekly, .annual, .monthly],
                imageNames: [TestData.paywallHeaderImageName,
                             TestData.paywallBackgroundImageName],
                colors: .init(
                    light: .init(
                        background: "#FFFFFF",
                        foreground: "#000000",
                        callToActionBackground: "#EC807C",
                        callToActionForeground: "#FFFFFF"
                    ),
                    dark: .init(
                        background: "#000000",
                        foreground: "#FFFFFF",
                        callToActionBackground: "#ACD27A",
                        callToActionForeground: "#000000"
                    )
                ),
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!,
                privacyURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localization: localization,
            assetBaseURL: TestData.paywallAssetBaseURL
        ),
        availablePackages: [TestData.weeklyPackage,
                            TestData.monthlyPackage,
                            TestData.annualPackage]
    )

    private static let localization: PaywallData.LocalizedConfiguration = .init(
        title: "Despierta la curiosidad de tu hijo",
        subtitle: "Accede a todo nuestro contenido educativo, confiado por miles de padres.",
        callToAction: "Comprar",
        offerDetails: "{{ total_price_and_per_month }}",
        offerDetailsWithIntroOffer: "Comienza tu prueba de {{ intro_duration }}, después {{ price_per_month }} cada mes"
    )

}
