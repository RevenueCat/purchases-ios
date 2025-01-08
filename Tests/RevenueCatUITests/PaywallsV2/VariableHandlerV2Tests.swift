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

    static let localizations = [
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
    
    static let variableMapping: [String: String] = [:]
    static let functionMapping: [String: String] = [:]

    static let locale = Locale(identifier: "en_US")

    let variableHandler = VariableHandlerV2(
        discountRelativeToMostExpensivePerMonth: nil,
        showZeroDecimalPlacePrices: false,
        variableMapping: variableMapping,
        functionMapping: functionMapping,
        locale: locale,
        localizations: localizations["en_US"]!,
        packages: []
    )

    func testProductCurrencyCode() {
        let result = variableHandler.processVariables(
            in: "{{ product.currency_code }}",
            with: TestData.monthlyPackage
        )

        expect(result).to(equal("USD"))
    }

    func testProductCurrencySymbol() {
        let result = variableHandler.processVariables(
            in: "{{ product.currency_symbol }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$"))
    }

    func testProductPeriodly() {
        let result = variableHandler.processVariables(
            in: "{{ product.periodly }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("monthly"))
    }

    func testProductPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.price }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$6.99"))
    }

    func testProductPricePerPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$6.99/month"))
    }

    func testProductPricePerPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_period_abbreviated }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$6.99/mo"))
    }

    func testProductPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_day }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$0.23"))
    }

    func testProductPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_week }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$1.61"))
    }

    func testProductPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_month }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$6.99"))
    }

    func testProductPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.price_per_year }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("$83.88"))
    }

    func testProductPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.period }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("month"))
    }

    func testProductPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_abbreviated }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("mo"))
    }

    func testProductPeriodInDays() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_days }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("30"))
    }

    func testProductPeriodInWeeks() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_weeks }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("4"))
    }

    func testProductPeriodInMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_months }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("1"))
    }

    func testProductPeriodInYears() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_in_years }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("0"))
    }

    func testProductPeriodWithUnit1Month() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_with_unit }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("1 month"))
    }

    func testProductPeriodWithUnit3Months() {
        let result = variableHandler.processVariables(
            in: "{{ product.period_with_unit }}",
            with: TestData.threeMonthPackage
        )
        expect(result).to(equal("3 months"))
    }

    func testProductFreeOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_day }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_week }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal("free"))
    }

    func testProductFreeOfferPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_month }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal(""))
    }

    func testProductFreeOfferPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_year }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal(""))
    }

    func testProductPayUpFrontOfferPrice() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price }}",
            with: TestData.packageWithIntroOfferPayUpFront
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductPayUpFrontOfferPricePerDay() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_day }}",
            with: TestData.packageWithIntroOfferPayUpFront
        )
        expect(result).to(equal("$0.28"))
    }

    func testProductPayUpFrontOfferPricePerWeek() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_week }}",
            with: TestData.packageWithIntroOfferPayUpFront
        )
        expect(result).to(equal("$1.99"))
    }

    func testProductPayUpFrontOfferPricePerMonth() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_month }}",
            with: TestData.packageWithIntroOfferPayUpFront
        )
        expect(result).to(equal(""))
    }

    func testProductPayUpFrontOfferPricePerYear() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_price_per_year }}",
            with: TestData.packageWithIntroOfferPayUpFront
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal("week"))
    }

    func testProductOfferPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_abbreviated }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal("wk"))
    }

    func testProductOfferPeriodInDays() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_days }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal("7"))
    }

    func testProductOfferPeriodInWeeks() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_weeks }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal("1"))
    }

    func testProductOfferPeriodInMonths() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_months }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriodInYears() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_in_years }}",
            with: TestData.packageWithIntroOffer
        )
        expect(result).to(equal(""))
    }

    func testProductOfferPeriodWithUnit() {
        let result = variableHandler.processVariables(
            in: "{{ product.offer_period_with_unit }}",
            with: TestData.packageWithIntroOffer
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
            with: TestData.monthlyPackage
        )
        expect(result).to(equal(""))
    }

    func testProductSecondaryOfferPeriod() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_period }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal(""))
    }

    func testProductSecondaryOfferPeriodAbbreviated() {
        let result = variableHandler.processVariables(
            in: "{{ product.secondary_offer_period_abbreviated }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal(""))
    }

    func testProductRelativeDiscount() {
        let variableHandler = VariableHandlerV2(
            discountRelativeToMostExpensivePerMonth: 0.3,
            showZeroDecimalPlacePrices: false,
            variableMapping: Self.variableMapping,
            functionMapping: Self.functionMapping,
            locale: Self.locale,
            localizations: Self.localizations["en_US"]!,
            packages: []
        )

        let result = variableHandler.processVariables(
            in: "{{ product.relative_discount }}",
            with: TestData.monthlyPackage
        )
        expect(result).to(equal("30%"))
    }
    
    func testLiquid() {
        let packageResolver: (String) -> [String: Any]? = { packageId in
            return nil
        }
        
        let functions: [String: TemplateFunction] = [
            "uppercase": { _, args in
                guard let str = args.first as? String else { return "" }
                return str.uppercased()
            },
        ]

        var context: [String: Any] = [
            "product": [
                "store_product_name": "Premium Pro",
                "price_per_period": "$9.99/mo",
                "has_free_trial": false
            ]
        ]

        let liquid = Liquid(functions: functions, packageResolver: packageResolver)

        let template = """
        {% if product.has_free_trial == true %}
        You got a free trial {{ product.price_per_period }}
        {% else %}
        You do not have a free trial {{ product.price_per_period }}
        {% endif %}
        """

        let output = liquid.render(template: template, context: &context)
        print(output)
    }

    
    func testLiquid2() {
        let packageResolver: (String) -> [String: Any]? = { packageId in
            let products = [
                "basic": ["price": 9.99, "name": "Basic Package"],
                "premium": ["price": 19.99, "name": "Premium Package"]
            ]
            return products[packageId]
        }

        let functions: [String: TemplateFunction] = [:]

        var context: [String: Any] = [:]

        let liquid = Liquid(functions: functions, packageResolver: packageResolver)

        let template = """
        {% package: "basic" %}
        Product: {{ product.name }}
        Price: {{ product.price }}
        {% endpackage %}

        {% package: "premium" %}
        Product: {{ product.name }}
        Price: {{ product.price }}
        {% endpackage %}
        """

        let output = liquid.render(template: template, context: &context)
        print(output)
    }
}
