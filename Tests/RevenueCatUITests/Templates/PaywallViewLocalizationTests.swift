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
            purchaseHandler: Self.purchaseHandler
        )
    }

     private static let offering = Offering(
        identifier: "offering",
        serverDescription: "Offering",
        metadata: [:],
        paywall: .init(
            template: .template2,
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
        offerDetailsWithIntroOffer: "Comienza tu prueba de {{ sub_offer_duration }}, " +
        "después {{ sub_price_per_month }} cada mes",
        features: []
    )

}
