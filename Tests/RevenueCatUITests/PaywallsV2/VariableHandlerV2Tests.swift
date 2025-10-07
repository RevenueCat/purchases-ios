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
@testable import RevenueCatUI
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

    func testProductPeriodlyMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.periodly }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("3 months"))
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

    func testProductPricePerPeriodMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$4.99/3 months"))
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

    func testProductPricePerPeriodAbbreviatedMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period_abbreviated }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("$4.99/3mo"))
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

    func testProductPeriodMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.period }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("3 months"))
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

    func testProductPeriodAbbreviatedMultipleMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_abbreviated }}",
            with: TestData.threeMonthPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("3mo"))
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

    func testProductPayUpFrontPromoOfferPrice() {
        let discount = TestData.packageWithPromoOfferPayUpFront.storeProduct.discounts.first!
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithPromoOfferPayUpFront,
            locale: locale,
            localizations: localizations["en_US"]!,
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

    func testProductOfferEndDate() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_end_date }}",
            with: TestData.packageWithIntroOffer,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("December 19, 2024"))
    }

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
            variableCompatibilityMap: Self.variableMapping,
            functionCompatibilityMap: Self.functionMapping,
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

    func testFunctionUppercase() {
        let result = variableHandler.processVariables(
            in: "{{ product.period | uppercase }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("MONTH"))
    }

    func testFunctionLowercase() {
        let result = variableHandler.processVariables(
            in: "{{ product.period | lowercase }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("month"))
    }

    func testFunctionCapitalize() {
        let result = variableHandler.processVariables(
            in: "{{ product.period | capitalize }}",
            with: TestData.monthlyPackage,
            locale: locale,
            localizations: localizations["en_US"]!
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
            localizations: localizations["en_US"]!
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
            localizations: localizations["en_US"]!
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
            localizations: localizations["en_US"]!
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
            localizations: localizations["en_US"]!
        )
        expect(result).to(equal("Monthly"))
    }

}

#endif
