//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VariableHandlerV2Tests.swift
//
//  Created by Josh Holtz on 1/5/25.
// swiftlint:disable file_length type_body_length 

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class VariableHandlerV2Test: TestCase {

    let localizations = [
        "en_US": [
            "weekly": "weekly",
            "week": "week",
            "wk": "wk",
            "monthly": "monthly",
            "month": "month",
            "mo": "mo",
            "%d day": "%d day",
            "%d days": "%d days",
            "%d week": "%d week",
            "%d weeks": "%d weeks",
            "%d month": "%d month",
            "%d months": "%d months",
            "%d year": "%d year",
            "%d years": "%d years",
            "%d%%": "%d%%",
            "free": "free"
        ],
        "es_ES": [
            "month": "month"
        ]
    ]

    let locale = Locale(identifier: "en_US")

    let variableHandler = VariableHandlerV2(
        discountRelativeToMostExpensivePerMonth: nil,
        showZeroDecimalPlacePrices: false
    )

    func testProductCurrencyCode() {
        let result = variableHandler.processVariables(
            in: "{{ product.currency_code }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )

        expect(result).to(equal("USD"))
    }

    func testProductCurrencySymbol() {
        let result = variableHandler.processVariables(
            in: "{{ product.currency_symbol }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$"))
    }

    func testProductPeriodly() {
        let result = variableHandler.processVariables(
            in: "{{ product.periodly }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("monthly"))
    }

    func testProductPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.price }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$6.99"))
    }

    func testProductPricePerPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$6.99/month"))
    }

    func testProductPricePerPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period_abbreviated }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$6.99/mo"))
    }

    func testProductPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_day }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$0.23"))
    }

    func testProductPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_week }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$1.61"))
    }

    func testProductPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_month }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$6.99"))
    }

    func testProductPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_year }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$83.88"))
    }

    func testProductPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.period }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("month"))
    }

    func testProductPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_abbreviated }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("mo"))
    }

    func testProductPeriodInDays() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_days }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("30"))
    }

    func testProductPeriodInWeeks() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_weeks }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("4"))
    }

    func testProductPeriodInMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_months }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("1"))
    }

    func testProductPeriodInYears() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_years }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("0"))
    }

    func testProductPeriodWithUnit1Month() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_with_unit }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("1 month"))
    }

    func testProductPeriodWithUnit3Months() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_with_unit }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("3 months"))
    }

    func testProductFreeOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_day }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_week }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_month }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductFreeOfferPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_year }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductPayUpFrontOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductPayUpFrontOfferPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_day }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$0.28"))
    }

    func testProductPayUpFrontOfferPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_week }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductPayUpFrontOfferPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_month }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductPayUpFrontOfferPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_year }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("week"))
    }

    func testProductOfferPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_abbreviated }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("wk"))
    }

    func testProductOfferPeriodInDays() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_days }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("7"))
    }

    func testProductOfferPeriodInWeeks() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_weeks }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("1"))
    }

    func testProductOfferPeriodInMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_months }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriodInYears() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_years }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriodWithUnit() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_with_unit }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("1 week"))
    }

//    func testProductOfferEndDate() {
//        let result = variableHandler.processVariables(
//            in: "{{ product.offer_end_date }}",
//            with: TestData.packageWithIntroOffer,
//            locale: locale,
//            localizations: localizations["en_US"]!
//        )
//        expect(result).to(equal("2025-01-31"))
//    }

    func testProductSecondaryOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_price }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductSecondaryOfferPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_period }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductSecondaryOfferPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_period_abbreviated }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal(""))
    }

    func testProductRelativeDiscount() {
        let variableHandler = VariableHandlerV2(
            discountRelativeToMostExpensivePerMonth: 0.3,
            showZeroDecimalPlacePrices: false
        )

        let result = variableHandler.processVariables(
            in: "{{ product.relative_discount }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("30%"))
    }

}
