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
@testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class VariableHandlerV2Test: TestCase {

    let localizations = [
        "en_US": [
            "day": "day",
            "daily": "daily",
            "day_short": "day",
            "week": "week",
            "weekly": "weekly",
            "week_short": "wk",
            "month": "month",
            "monthly": "monthly",
            "month_short": "mo",
            "year": "year",
            "yearly": "yearly",
            "year_short": "yr",
            "annual": "annual",
            "annually": "annually",
            "annual_short": "yr",
            "free_price": "free",
            "percent": "%d%%",
            "num_day_zero": "%d day",
            "num_day_one": "%d day",
            "num_day_two": "%d days",
            "num_day_few": "%d days",
            "num_day_many": "%d days",
            "num_day_other": "%d days",
            "num_week_zero": "%d week",
            "num_week_one": "%d week",
            "num_week_two": "%d weeks",
            "num_week_few": "%d weeks",
            "num_week_many": "%d weeks",
            "num_week_other": "%d weeks",
            "num_month_zero": "%d month",
            "num_month_one": "%d month",
            "num_month_two": "%d months",
            "num_month_few": "%d months",
            "num_month_many": "%d months",
            "num_month_other": "%d months",
            "num_year_zero": "%d year",
            "num_year_one": "%d year",
            "num_year_two": "%d years",
            "num_year_few": "%d years",
            "num_year_many": "%d years",
            "num_year_other": "%d years",
            "num_days_short": "%dd",
            "num_weeks_short": "%dwk",
            "num_months_short": "%dmo",
            "num_years_short": "%dyr"
        ]
    ]

    let locale = Locale(identifier: "en_US")

    static let variableMapping: [String: String] = [:]
    static let functionMapping: [String: String] = [:]

    let variableHandler = VariableHandlerV2(
        variableCompatibilityMap: variableMapping,
        functionCompatibilityMap: functionMapping,
        discountRelativeToMostExpensivePerMonth: nil,
        showZeroDecimalPlacePrices: false,
        dateProvider: {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: "2024-12-12")!
        }
    )

    func testProductCurrencyCode() {
        let result = variableHandler.processVariables(
            in: "{{ product.currency_code }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )

        expect(result).to(equal("USD"))
    }

    func testProductCurrencySymbol() {
        let result = variableHandler.processVariables(
            in: "{{ product.currency_symbol }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$"))
    }

    func testProductPeriodly() {
        let result = variableHandler.processVariables(
            in: "{{ product.periodly }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("monthly"))
    }

    func testProductPeriodlyMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.periodly }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("3 months"))
    }

    func testProductPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.price }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$6.99"))
    }

    func testProductPricePerPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$6.99/month"))
    }

    func testProductPricePerPeriodMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$4.99/3 months"))
    }

    func testProductPricePerPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period_abbreviated }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$6.99/mo"))
    }

    func testProductPricePerPeriodAbbreviatedMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period_abbreviated }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$4.99/3mo"))
    }

    func testProductPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_day }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$0.23"))
    }

    func testProductPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_week }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$1.60"))
    }

    func testProductPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_month }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$6.99"))
    }

    func testProductPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_year }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$83.88"))
    }

    func testProductPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.period }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("month"))
    }

    func testProductPeriodMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.period }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("3 months"))
    }

    func testProductPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_abbreviated }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("mo"))
    }

    func testProductPeriodAbbreviatedMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_abbreviated }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("3mo"))
    }

    func testProductPeriodInDays() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_days }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("30"))
    }

    func testProductPeriodInWeeks() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_weeks }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("4"))
    }

    func testProductPeriodInMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_months }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("1"))
    }

    func testProductPeriodInYears() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_years }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("0"))
    }

    func testProductPeriodWithUnit1Month() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_with_unit }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("1 month"))
    }

    func testProductPeriodWithUnit3Months() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_with_unit }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("3 months"))
    }

    func testProductFreeOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_day }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_week }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_month }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductFreeOfferPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_year }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductPayUpFrontOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductPayUpFrontOfferPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_day }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$0.28"))
    }

    func testProductPayUpFrontPromoOfferPrice() {
        let discount = TestData.packageWithPromoOfferPayUpFront.storeProduct.discounts.first!
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithPromoOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true,
            promoOffer: .init(
                discount: discount,
                signedData: .init(identifier: "", keyIdentifier: "", nonce: .init(), signature: "", timestamp: 0)
            )
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductPayUpFrontPromoOfferPricePerDay() {
        let discount = TestData.packageWithPromoOfferPayUpFront.storeProduct.discounts.first!

        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_day }}",
            with: TestData.packageWithPromoOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true,
            promoOffer: .init(
                discount: discount,
                signedData: .init(identifier: "", keyIdentifier: "", nonce: .init(), signature: "", timestamp: 0)
            )
        )
        expect(result).to(equal("$0.28"))
    }

    func testProductPayUpFrontOfferPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_week }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductPayUpFrontOfferPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_month }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductPayUpFrontOfferPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_year }}",
            with: TestData.packageWithIntroOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("week"))
    }

    func testProductOfferPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_abbreviated }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("wk"))
    }

    func testProductOfferPeriodInDays() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_days }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("7"))
    }

    func testProductOfferPeriodInWeeks() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_weeks }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("1"))
    }

    func testProductOfferPeriodInMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_months }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriodInYears() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_years }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriodWithUnit() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_with_unit }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("1 week"))
    }

    func testProductOfferEndDate() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_end_date }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("December 19, 2024"))
    }

    func testProductSecondaryOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_price }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductSecondaryOfferPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_period }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductSecondaryOfferPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_period_abbreviated }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    // MARK: - Intro Offer Ineligibility Tests

    func testOfferPriceReturnsEmptyWhenNotEligibleForIntroOffer() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: false
        )
        expect(result).to(equal(""))
    }

    func testOfferPeriodReturnsEmptyWhenNotEligibleForIntroOffer() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: false
        )
        expect(result).to(equal(""))
    }

    func testOfferPricePerWeekReturnsEmptyWhenNotEligibleForIntroOffer() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_week }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: false
        )
        expect(result).to(equal(""))
    }

    func testOfferEndDateReturnsEmptyWhenNotEligibleForIntroOffer() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_end_date }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: false
        )
        expect(result).to(equal(""))
    }

    func testPromoOfferShownEvenWhenNotEligibleForIntroOffer() {
        let discount = TestData.packageWithPromoOfferPayUpFront.storeProduct.discounts.first!
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithPromoOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: false,
            promoOffer: .init(
                discount: discount,
                signedData: .init(identifier: "", keyIdentifier: "", nonce: .init(), signature: "", timestamp: 0)
            )
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductRelativeDiscount() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: Self.variableMapping,
            functionCompatibilityMap: Self.functionMapping,
            discountRelativeToMostExpensivePerMonth: 0.3,
            showZeroDecimalPlacePrices: false
        )

        let result = variableHandler.processVariables(
            in: "{{ product.relative_discount }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("30%"))
    }

    func testFunctionUppercase() {
        let result = variableHandler.processVariables(
            in: "{{ product.period | uppercase }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("MONTH"))
    }

    func testFunctionLowercase() {
        let result = variableHandler.processVariables(
            in: "{{ product.period | lowercase }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("month"))
    }

    func testFunctionCapitalize() {
        let result = variableHandler.processVariables(
            in: "{{ product.period | capitalize }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Month"))
    }

    func testVariableMapping() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [
                "product_name": "product.store_product_name"
            ],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: 0.3,
            showZeroDecimalPlacePrices: false
        )

        let result = variableHandler.processVariables(
            in: "Name is {{ product_name }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Name is Monthly"))
    }

    func testVariableMappingWithNoMapping() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: 0.3,
            showZeroDecimalPlacePrices: false
        )

        let result = variableHandler.processVariables(
            in: "Name is {{ product_name_that_does_not_exist }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Name is "))
    }

    func testFunctionMapping() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [
                "loud": "uppercase"
            ],
            discountRelativeToMostExpensivePerMonth: 0.3,
            showZeroDecimalPlacePrices: false
        )

        let result = variableHandler.processVariables(
            in: "{{ product.store_product_name || loud }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("MONTHLY"))
    }

    func testFunctionMappingWithNoMapping() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: 0.3,
            showZeroDecimalPlacePrices: false
        )

        let result = variableHandler.processVariables(
            in: "{{ product.store_product_name || loud }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Monthly"))
    }

    // MARK: - Non-Subscription Tests

    func testProductPricePerPeriodForLifetime() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.lifetimePackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        // Lifetime products should not have a period suffix (no slash)
        expect(result).to(equal("$119.49"))
    }

    func testProductPricePerPeriodAbbreviatedForLifetime() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period_abbreviated }}",
            with: TestData.lifetimePackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        // Lifetime products should not have a period suffix (no slash)
        expect(result).to(equal("$119.49"))
    }

    func testProductPricePerPeriodForConsumable() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.consumablePackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        // Consumable products should not have a period suffix (no slash)
        expect(result).to(equal("$4.99"))
    }

    func testProductPricePerPeriodAbbreviatedForConsumable() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period_abbreviated }}",
            with: TestData.consumablePackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        // Consumable products should not have a period suffix (no slash)
        expect(result).to(equal("$4.99"))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class V2ZeroDecimalPlacePricesTest: TestCase {

    let localizations = [
        "en_US": [
            "day": "day",
            "daily": "daily",
            "day_short": "day",
            "week": "week",
            "weekly": "weekly",
            "week_short": "wk",
            "month": "month",
            "monthly": "monthly",
            "month_short": "mo",
            "year": "year",
            "yearly": "yearly",
            "year_short": "yr",
            "annual": "annual",
            "annually": "annually",
            "annual_short": "yr",
            "free_price": "free",
            "percent": "%d%%",
            "num_day_zero": "%d day",
            "num_day_one": "%d day",
            "num_day_two": "%d days",
            "num_day_few": "%d days",
            "num_day_many": "%d days",
            "num_day_other": "%d days",
            "num_week_zero": "%d week",
            "num_week_one": "%d week",
            "num_week_two": "%d weeks",
            "num_week_few": "%d weeks",
            "num_week_many": "%d weeks",
            "num_week_other": "%d weeks",
            "num_month_zero": "%d month",
            "num_month_one": "%d month",
            "num_month_two": "%d months",
            "num_month_few": "%d months",
            "num_month_many": "%d months",
            "num_month_other": "%d months",
            "num_year_zero": "%d year",
            "num_year_one": "%d year",
            "num_year_two": "%d years",
            "num_year_few": "%d years",
            "num_year_many": "%d years",
            "num_year_other": "%d years",
            "num_days_short": "%dd",
            "num_weeks_short": "%dwk",
            "num_months_short": "%dmo",
            "num_years_short": "%dyr"
        ]
    ]

    let locale = Locale(identifier: "en_US")

    // Variable handler with showZeroDecimalPlacePrices enabled
    let variableHandlerWithZeroDecimal = VariableHandlerV2(
        variableCompatibilityMap: [:],
        functionCompatibilityMap: [:],
        discountRelativeToMostExpensivePerMonth: nil,
        showZeroDecimalPlacePrices: true,
        dateProvider: {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: "2024-12-12")!
        }
    )

    // Variable handler with showZeroDecimalPlacePrices disabled (default)
    let variableHandlerWithoutZeroDecimal = VariableHandlerV2(
        variableCompatibilityMap: [:],
        functionCompatibilityMap: [:],
        discountRelativeToMostExpensivePerMonth: nil,
        showZeroDecimalPlacePrices: false,
        dateProvider: {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: "2024-12-12")!
        }
    )

    func testProductPriceWithZeroDecimalPlacePrices() {
        // With showZeroDecimalPlacePrices: true, whole number prices should not show .00
        let resultWithZeroDecimal = variableHandlerWithZeroDecimal.processVariables(
            in: "{{ product.price }}",
            with: TestData.annualPackage60,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithZeroDecimal).to(equal("$60"))

        // With showZeroDecimalPlacePrices: false, whole number prices should show .00
        let resultWithoutZeroDecimal = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.price }}",
            with: TestData.annualPackage60,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithoutZeroDecimal).to(equal("$60.00"))
    }

    func testProductPricePerMonthWithZeroDecimalPlacePrices() {
        // With showZeroDecimalPlacePrices: true, whole number prices should not show .00
        let resultWithZeroDecimal = variableHandlerWithZeroDecimal.processVariables(
            in: "{{ product.price_per_month }}",
            with: TestData.annualPackage60,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithZeroDecimal).to(equal("$5"))

        // With showZeroDecimalPlacePrices: false, whole number prices should show .00
        let resultWithoutZeroDecimal = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.price_per_month }}",
            with: TestData.annualPackage60,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithoutZeroDecimal).to(equal("$5.00"))
    }

    func testProductPricePerPeriodWithZeroDecimalPlacePrices() {
        // With showZeroDecimalPlacePrices: true
        let resultWithZeroDecimal = variableHandlerWithZeroDecimal.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.annualPackage60,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithZeroDecimal).to(equal("$60/year"))

        // With showZeroDecimalPlacePrices: false
        let resultWithoutZeroDecimal = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.annualPackage60,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithoutZeroDecimal).to(equal("$60.00/year"))
    }

    func testNonWholeNumberPricesAreUnaffected() {
        // Non-whole number prices should show decimals regardless of flag
        let resultWithZeroDecimal = variableHandlerWithZeroDecimal.processVariables(
            in: "{{ product.price }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithZeroDecimal).to(equal("$6.99"))

        let resultWithoutZeroDecimal = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.price }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(resultWithoutZeroDecimal).to(equal("$6.99"))
    }

    // MARK: - Optional Package Tests

    func testProductVariablesReturnEmptyStringWhenPackageIsNil() {
        let result = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.price }}",
            with: nil,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductCurrencyCodeReturnsEmptyStringWhenPackageIsNil() {
        let result = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.currency_code }}",
            with: nil,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductPricePerPeriodReturnsEmptyStringWhenPackageIsNil() {
        let result = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.price_per_period }}",
            with: nil,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductPeriodReturnsEmptyStringWhenPackageIsNil() {
        let result = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.period }}",
            with: nil,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testProductStoreProductNameReturnsEmptyStringWhenPackageIsNil() {
        let result = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.store_product_name }}",
            with: nil,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal(""))
    }

    func testNonProductVariablesWorkWhenPackageIsNil() {
        // Currency symbol doesn't require a package
        let result = variableHandlerWithoutZeroDecimal.processVariables(
            in: "{{ product.currency_symbol }}",
            with: nil,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("$"))
    }

    func testRelativeDiscountWorksWhenPackageIsNil() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: 0.25,
            showZeroDecimalPlacePrices: false
        )

        let result = variableHandler.processVariables(
            in: "{{ product.relative_discount }}",
            with: nil,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("25%"))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class CustomVariablesV2Tests: TestCase {

    let localizations = [
        "en_US": [
            "month": "month"
        ]
    ]

    let locale = Locale(identifier: "en_US")

    // MARK: - Custom Variables Tests

    func testCustomVariableWithSDKProvidedValue() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["player_name": .string("John")],
            defaultCustomVariables: ["player_name": .string("Player")]
        )

        let result = variableHandler.processVariables(
            in: "Hello {{ custom.player_name }}!",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Hello John!"))
    }

    func testCustomVariableFallsBackToDefaultValue() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: [:],
            defaultCustomVariables: ["player_name": .string("Player")]
        )

        let result = variableHandler.processVariables(
            in: "Hello {{ custom.player_name }}!",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Hello Player!"))
    }

    func testCustomVariableReturnsEmptyWhenNotFound() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: [:],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Hello {{ custom.unknown_var }}!",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Hello !"))
    }

    func testCustomVariableWithFunction() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["player_name": .string("john")],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Hello {{ custom.player_name | uppercase }}!",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Hello JOHN!"))
    }

    func testCustomVariableWithNumericValue() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["max_health": .number(100)],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Your max health is {{ custom.max_health }}.",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Your max health is 100."))
    }

    func testCustomVariableWithBooleanValue() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["is_premium": .bool(true)],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Premium status: {{ custom.is_premium }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Premium status: true"))
    }

    func testMultipleCustomVariables() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: [
                "player_name": .string("John"),
                "level": .number(42)
            ],
            defaultCustomVariables: [
                "max_health": .number(100)
            ]
        )

        let result = variableHandler.processVariables(
            in: "{{ custom.player_name }} (Level {{ custom.level }}) - Max HP: {{ custom.max_health }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("John (Level 42) - Max HP: 100"))
    }

    func testCustomVariableMixedWithBuiltInVariables() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["player_name": .string("John")],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Hello {{ custom.player_name }}! Subscribe for {{ product.price }}/{{ product.period }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Hello John! Subscribe for $6.99/month"))
    }

    func testSDKProvidedValueOverridesDefault() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["setting": .string("override")],
            defaultCustomVariables: ["setting": .string("default")]
        )

        let result = variableHandler.processVariables(
            in: "Setting: {{ custom.setting }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Setting: override"))
    }

    func testCustomVariableWithDecimalNumber() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["price": .number(9.99)],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Price: {{ custom.price }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Price: 9.99"))
    }

    func testCustomVariableWithNegativeNumber() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["offset": .number(-10)],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Offset: {{ custom.offset }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Offset: -10"))
    }

    func testCustomVariableWithBooleanFalse() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["enabled": .bool(false)],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Enabled: {{ custom.enabled }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Enabled: false"))
    }

    func testCustomVariableNumberWithFunction() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["level": .number(42)],
            defaultCustomVariables: [:]
        )

        // Functions like uppercase on a number just return the number as string
        let result = variableHandler.processVariables(
            in: "Level: {{ custom.level | uppercase }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Level: 42"))
    }

    func testCustomVariableBoolWithFunction() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["enabled": .bool(true)],
            defaultCustomVariables: [:]
        )

        let result = variableHandler.processVariables(
            in: "Status: {{ custom.enabled | uppercase }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Status: TRUE"))
    }

    func testDefaultCustomVariableWithDifferentTypeThanSDKProvided() {
        // SDK provides a number, default is a string - SDK value should win
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["value": .number(100)],
            defaultCustomVariables: ["value": .string("default")]
        )

        let result = variableHandler.processVariables(
            in: "Value: {{ custom.value }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Value: 100"))
    }

    func testVariableLookingLikeCustomButIncorrectSyntaxReturnsEmpty() {
        let variableHandler = VariableHandlerV2(
            variableCompatibilityMap: [:],
            functionCompatibilityMap: [:],
            discountRelativeToMostExpensivePerMonth: nil,
            showZeroDecimalPlacePrices: false,
            customVariables: ["player": .string("John")],
            defaultCustomVariables: [:]
        )

        // Using "custom_player" instead of "custom.player" - should return empty
        // and log a warning about incorrect syntax
        let result = variableHandler.processVariables(
            in: "Hello {{ custom_player }}!",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!,
            isEligibleForIntroOffer: true
        )
        expect(result).to(equal("Hello !"))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class CustomVariableValueTests: TestCase {

    // MARK: - stringValue Tests

    func testStringValueForString() {
        let value = CustomVariableValue.string("Hello")
        expect(value.stringValue).to(equal("Hello"))
    }

    func testStringValueForWholeNumber() {
        let value = CustomVariableValue.number(100.0)
        expect(value.stringValue).to(equal("100"))
    }

    func testStringValueForDecimalNumber() {
        let value = CustomVariableValue.number(99.99)
        expect(value.stringValue).to(equal("99.99"))
    }

    func testStringValueForBoolTrue() {
        let value = CustomVariableValue.bool(true)
        expect(value.stringValue).to(equal("true"))
    }

    func testStringValueForBoolFalse() {
        let value = CustomVariableValue.bool(false)
        expect(value.stringValue).to(equal("false"))
    }

    // MARK: - doubleValue Tests

    func testDoubleValueForNumber() {
        let value = CustomVariableValue.number(42.5)
        expect(value.doubleValue).to(equal(42.5))
    }

    func testDoubleValueForString() {
        let value = CustomVariableValue.string("123.45")
        expect(value.doubleValue).to(equal(123.45))
    }

    func testDoubleValueForInvalidString() {
        let value = CustomVariableValue.string("not a number")
        expect(value.doubleValue).to(equal(0))
    }

    func testDoubleValueForBoolTrue() {
        let value = CustomVariableValue.bool(true)
        expect(value.doubleValue).to(equal(1.0))
    }

    func testDoubleValueForBoolFalse() {
        let value = CustomVariableValue.bool(false)
        expect(value.doubleValue).to(equal(0.0))
    }

    // MARK: - boolValue Tests

    func testBoolValueForBool() {
        expect(CustomVariableValue.bool(true).boolValue).to(beTrue())
        expect(CustomVariableValue.bool(false).boolValue).to(beFalse())
    }

    func testBoolValueForNumber() {
        expect(CustomVariableValue.number(1).boolValue).to(beTrue())
        expect(CustomVariableValue.number(42).boolValue).to(beTrue())
        expect(CustomVariableValue.number(-1).boolValue).to(beTrue())
        expect(CustomVariableValue.number(0).boolValue).to(beFalse())
    }

    func testBoolValueForString() {
        expect(CustomVariableValue.string("true").boolValue).to(beTrue())
        expect(CustomVariableValue.string("TRUE").boolValue).to(beTrue())
        expect(CustomVariableValue.string("1").boolValue).to(beTrue())
        expect(CustomVariableValue.string("yes").boolValue).to(beTrue())
        expect(CustomVariableValue.string("YES").boolValue).to(beTrue())
        expect(CustomVariableValue.string("false").boolValue).to(beFalse())
        expect(CustomVariableValue.string("0").boolValue).to(beFalse())
        expect(CustomVariableValue.string("no").boolValue).to(beFalse())
        expect(CustomVariableValue.string("random").boolValue).to(beFalse())
    }

    // MARK: - ExpressibleBy Literal Tests

    func testExpressibleByStringLiteral() {
        let value: CustomVariableValue = "test"
        expect(value).to(equal(.string("test")))
    }

    // MARK: - Dictionary Conversion Tests

    func testAsStringDictionary() {
        let variables: [String: CustomVariableValue] = [
            "name": .string("John"),
            "level": .number(42),
            "premium": .bool(true)
        ]

        let stringDict = variables.asStringDictionary

        expect(stringDict["name"]).to(equal("John"))
        expect(stringDict["level"]).to(equal("42"))
        expect(stringDict["premium"]).to(equal("true"))
    }

}

#endif
