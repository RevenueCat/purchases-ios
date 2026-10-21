//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class RelativeDiscountTests: TestCase {

    @MainActor
    func testMonthlyAndAnnualDiscountUsesUnroundedPrices() throws {
        let packages = [
            self.package(price: 29.99, period: .init(value: 1, unit: .year), currency: "GBP"),
            self.package(price: 2.99, period: .init(value: 1, unit: .month), currency: "GBP")
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "16%", expectedPrices: "£2.49|£0.57")
    }

    @MainActor
    func testWeeklyAndAnnualDiscountUsesUnroundedPricesForBothPackages() throws {
        let packages = [
            self.package(price: 12.99, period: .init(value: 1, unit: .year)),
            self.package(price: 1.99, period: .init(value: 1, unit: .week))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "87%", expectedPrices: "$1.08|$0.24")
    }

    @MainActor
    func testHalfPercentageRoundsUpWithoutFloatingPointError() throws {
        let packages = [
            self.package(price: 11.58, period: .init(value: 1, unit: .year)),
            self.package(price: 1, period: .init(value: 1, unit: .month))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "4%", expectedPrices: "$0.96|$0.22")
    }

    @MainActor
    func testWeeklyHalfPercentageRoundsUpWithoutRepeatingDecimalError() throws {
        let packages = [
            self.package(price: 10.95, period: .init(value: 1, unit: .year)),
            self.package(price: 0.24, period: .init(value: 1, unit: .week))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "13%", expectedPrices: "$0.91|$0.21")
    }

    @MainActor
    func testWeeklyHalfPercentDiscountRoundsUpToOnePercent() throws {
        let packages = [
            self.package(price: 145.27, period: .init(value: 1, unit: .year)),
            self.package(price: 2.80, period: .init(value: 1, unit: .week))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "1%", expectedPrices: "$12.10|$2.78")
    }

    @MainActor
    func testDailyBaselineUsesExistingMonthlyConversion() throws {
        let packages = [
            self.package(price: 29.99, period: .init(value: 1, unit: .year)),
            self.package(price: 0.10, period: .init(value: 1, unit: .day))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "17%", expectedPrices: "$2.49|$0.57")
    }

    @MainActor
    func testMultiplePeriodUnitsAreIncludedInDiscount() throws {
        let packages = [
            self.package(price: 59.98, period: .init(value: 2, unit: .year)),
            self.package(price: 5.98, period: .init(value: 2, unit: .month))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "16%", expectedPrices: "$2.49|$0.57")
    }

    @MainActor
    func testEqualMonthlyPricesHaveNoDiscount() throws {
        let packages = [
            self.package(price: 24, period: .init(value: 1, unit: .year)),
            self.package(price: 2, period: .init(value: 1, unit: .month))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "", expectedPrices: "$2.00|$0.46")
    }

    @MainActor
    func testFreePackagesHaveNoDiscount() throws {
        let packages = [
            self.package(price: 0, period: .init(value: 1, unit: .year)),
            self.package(price: 0, period: .init(value: 1, unit: .month))
        ]

        try self.assertDiscount(packages: packages, expectedDiscount: "", expectedPrices: "$0.00|$0.00")
    }

    private func package(price: Decimal, period: SubscriptionPeriod, currency: String = "USD") -> Package {
        let product = TestStoreProduct(
            localizedTitle: "Subscription",
            price: price,
            currencyCode: currency,
            localizedPriceString: "\(price)",
            productIdentifier: "subscription_\(period.unit)_\(price)",
            productType: .autoRenewableSubscription,
            localizedDescription: "Subscription",
            subscriptionPeriod: period,
            locale: Locale(identifier: currency == "GBP" ? "en_GB" : "en_US")
        )
        return Package(
            identifier: product.productIdentifier,
            packageType: .custom,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "offering",
            webCheckoutUrl: nil
        )
    }

    @MainActor
    private func assertDiscount(packages: [Package], expectedDiscount: String, expectedPrices: String) throws {
        let annual = try XCTUnwrap(packages.first)
        let locale = Locale(identifier: annual.storeProduct.currencyCode == "GBP" ? "en_GB" : "en_US")
        let localization = PaywallData.LocalizedConfiguration(
            title: "{{ sub_relative_discount }}",
            subtitle: nil,
            callToAction: "Purchase",
            callToActionWithIntroOffer: nil,
            offerDetails: "{{ sub_price_per_month }}|{{ sub_price_per_week }}",
            offerDetailsWithIntroOffer: nil,
            features: []
        )
        let configuration = try TemplateViewConfiguration.PackageConfiguration.create(
            with: packages,
            filter: packages.map(\.identifier),
            default: nil,
            localization: localization,
            localizationByTier: [:],
            tiers: [],
            setting: .multiple,
            locale: locale
        )
        guard case let .multiple(data) = configuration else {
            return XCTFail("Expected multiple packages")
        }
        XCTAssertEqual(data.first.localization.title, expectedDiscount.isEmpty ? "" : "\(expectedDiscount) off")
        XCTAssertEqual(data.first.localization.offerDetails, expectedPrices)
        XCTAssertEqual(data.all[1].localization.title, "")

        let text = "{{ product.relative_discount }}|" +
            "{{ product.price_per_month }}|{{ product.price_per_week }}"
        let viewModel = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(locale: locale, localizedStrings: ["text": .string(text)]),
            uiConfigProvider: UIConfigProvider(uiConfig: .init(
                app: .init(colors: [:], fonts: [:]),
                localizations: [locale.identifier: ["percent": "%d%%"]],
                variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
            )),
            component: .init(text: "text", color: .init(light: .hex("#000000")))
        )
        var capturedText: String?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            selectedPackageId: annual.identifier,
            packageContext: .init(
                package: annual,
                variableContext: .init(packages: packages, showZeroDecimalPlacePrices: false)
            ),
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedText = style.text
            return EmptyView()
        }
        XCTAssertEqual(capturedText, "\(expectedDiscount)|\(expectedPrices)")
    }

}

#endif
