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

#if !os(watchOS) && !os(macOS)

private let spanishLocale = Locale(identifier: "es_ES")

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PaywallViewLocalizationTests: BaseSnapshotTest {

    func testSpanish() {
        Self.test(spanishLocale)
    }

 }

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewLocalizationTests {

    static func test(_ locale: Locale) {
        Self.createView(locale: locale)
            .snapshot(size: Self.fullScreenSize)
    }

    private static func createView(locale: Locale) -> some View {
        return Self.createPaywall(
            offering: Self.offering.withLocalImages,
            introEligibility: .init(checker: { packages in
                return Dictionary(
                    uniqueKeysWithValues: Set(packages)
                        .map { package in
                            let result: IntroEligibilityStatus = package.storeProduct.subscriptionPeriod?.unit == .month
                                ? .eligible
                                : .ineligible

                            return (package, result)
                        }
                )
            }),
            locale: locale
        )
    }

     private static let offering = Offering(
        identifier: "offering",
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
            templateName: PaywallTemplate.template2.rawValue,
            config: .init(
                packages: [PackageType.weekly.identifier,
                           PackageType.annual.identifier,
                           PackageType.monthly.identifier],
                images: TestData.images,
                colors: .init(
                    light: TestData.lightColors,
                    dark: TestData.lightColors
                ),
                termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!,
                privacyURL: URL(string: "https://revenuecat.com/tos")!
            ),
            localization: localization,
            assetBaseURL: TestData.paywallAssetBaseURL,
            locale: spanishLocale
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
        offerDetailsWithIntroOffer: "Comienza tu prueba de {{ sub_offer_duration }}, " +
        "después {{ sub_price_per_month }} cada mes",
        features: []
    )

}

#endif
