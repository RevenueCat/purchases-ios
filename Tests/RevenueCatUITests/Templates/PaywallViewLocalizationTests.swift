//
//  PaywallViewLocalizationTests.swift
//
//
//  Created by Nacho Soto on 7/17/23.
//

import Nimble
import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SnapshotTesting
import SwiftUI

#if !os(watchOS) && !os(macOS)

private let spanishLocale = "es_ES"
private let hebrewLocale  = "he-IL"
private let arabicLocale  = "ar"

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PaywallViewLocalizationTests: BaseSnapshotTest {

    func testSpanish() {
        Self.test(spanishLocale, offering: Self.spanishOffering)
    }

    // Regression tests for RTL layout direction.
    // When overridePreferredUILocale is set to an RTL locale while the system locale is LTR,
    // the paywall must render with RTL layout (not just RTL strings).
    func testHebrew() {
        Self.test(hebrewLocale, offering: Self.hebrewOffering)
    }

    func testArabic() {
        Self.test(arabicLocale, offering: Self.arabicOffering)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewLocalizationTests {

    static func test(_ locale: String, offering: Offering) {
        Self.createView(offering: offering, locale: locale)
            .snapshot(size: Self.fullScreenSize, record: Self.shouldRecordSnapshots, separateOSVersions: false)
    }

    private static func createView(offering: Offering, locale: String) -> some View {
        return Self.createPaywall(
            offering: offering.withLocalImages,
            localeOverride: locale
        )
    }

    static func makeOffering(localization: PaywallData.LocalizedConfiguration,
                             locale: String) -> Offering {
        return Offering(
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
                locale: Locale(identifier: locale)
            ),
            availablePackages: [TestData.weeklyPackage,
                                TestData.monthlyPackage,
                                TestData.annualPackage],
            webCheckoutUrl: nil
        )
    }

    // MARK: - Offerings

    static let spanishOffering = makeOffering(localization: .init(
        title: "Despierta la curiosidad de tu hijo",
        subtitle: "Accede a todo nuestro contenido educativo, confiado por miles de padres.",
        callToAction: "Comprar",
        offerDetails: "€9,99 al mes",
        features: []
    ), locale: spanishLocale)

    static let hebrewOffering = makeOffering(localization: .init(
        title: "עוררו את הסקרנות של ילדכם",
        subtitle: "גישה לכל התוכן החינוכי שלנו, בו בוטחים אלפי הורים.",
        callToAction: "לרכישה",
        offerDetails: "₪39.99 לחודש",
        features: []
    ), locale: hebrewLocale)

    static let arabicOffering = makeOffering(localization: .init(
        title: "أيقظ فضول طفلك",
        subtitle: "استمتع بجميع محتوياتنا التعليمية، التي يثق بها آلاف الآباء.",
        callToAction: "اشترِ الآن",
        offerDetails: "9.99 $ شهريًا",
        features: []
    ), locale: arabicLocale)

}

#endif
