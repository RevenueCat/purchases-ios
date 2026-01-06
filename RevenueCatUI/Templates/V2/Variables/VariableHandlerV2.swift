//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VariableHandlerV2.swift
//
//  Created by Josh Holtz on 1/5/25.
// swiftlint:disable file_length

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VariableHandlerV2 {

    private let variableCompatibilityMap: [String: String]
    private let functionCompatibilityMap: [String: String]

    private let showZeroDecimalPlacePrices: Bool
    private let discountRelativeToMostExpensivePerMonth: Double?
    private let dateProvider: () -> Date

    init(
        variableCompatibilityMap: [String: String],
        functionCompatibilityMap: [String: String],
        discountRelativeToMostExpensivePerMonth: Double?,
        showZeroDecimalPlacePrices: Bool,
        dateProvider: @escaping () -> Date = { Date() }
    ) {
        self.variableCompatibilityMap = variableCompatibilityMap
        self.functionCompatibilityMap = functionCompatibilityMap
        self.discountRelativeToMostExpensivePerMonth = discountRelativeToMostExpensivePerMonth
        self.showZeroDecimalPlacePrices = showZeroDecimalPlacePrices
        self.dateProvider = dateProvider
    }

    func processVariables(
        in text: String,
        with package: Package,
        locale: Locale,
        localizations: [String: String],
        promoOffer: PromotionalOffer? = nil,
        countdownTime: CountdownTime? = nil
    ) -> String {
        let whisker = Whisker(template: text) { variableRaw, functionRaw in
            let variable = self.findVariable(variableRaw)
            let function = functionRaw.flatMap { self.findFunction($0) }

            let processedVariable = variable?.process(
                package: package,
                locale: locale,
                localizations: localizations,
                discountRelativeToMostExpensivePerMonth: self.discountRelativeToMostExpensivePerMonth,
                date: self.dateProvider(),
                promoOffer: promoOffer,
                countdownTime: countdownTime
            ) ?? ""

            return function?.process(processedVariable) ?? processedVariable
        }

        return whisker.render()
    }

    private func findVariable(_ variableRaw: String) -> VariablesV2? {
        guard let originalVariable = VariablesV2(rawValue: variableRaw) else {

            let backSupportedVariableRaw = self.variableCompatibilityMap[variableRaw]

            guard let backSupportedVariableRaw else {
                Logger.error(
                    "Paywall variable '\(variableRaw)' is not supported " +
                    "and no backward compatible replacement found."
                )
                return nil
            }

            guard let backSupportedVariable = VariablesV2(rawValue: backSupportedVariableRaw) else {
                Logger.error(
                    "Paywall variable '\(variableRaw)' is not supported " +
                    "and could not find backward compatible '\(backSupportedVariableRaw)'."
                )
                return nil
            }

            Logger.warning(
                "Paywall variable '\(variableRaw)' is not supported. " +
                "Using backward compatible '\(backSupportedVariableRaw)' instead."
            )
            return backSupportedVariable
        }

        return originalVariable
    }

    private func findFunction(_ functionRaw: String) -> FunctionsV2? {
        guard let originalFunction = FunctionsV2(rawValue: functionRaw) else {

            let backSupportedFunctionRaw = self.functionCompatibilityMap[functionRaw]

            guard let backSupportedFunctionRaw else {
                Logger.error(
                    "Paywall function '\(functionRaw)' is not supported " +
                    "and no backward compatible replacement found.")
                return nil
            }

            guard let backSupportedFunction = FunctionsV2(rawValue: backSupportedFunctionRaw) else {
                Logger.error(
                    "Paywall variable '\(functionRaw)' is not supported " +
                    "and could not find backward compatible '\(backSupportedFunctionRaw)'.")
                return nil
            }

            Logger.warning(
                "Paywall function '\(functionRaw)' is not supported. " +
                "Using backward compatible '\(backSupportedFunction)' instead.")
            return backSupportedFunction
        }

        return originalFunction
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum VariableLocalizationKey: String {
    case day = "day"
    case daily = "daily"
    case dayShort = "day_short"
    case week = "week"
    case weekly = "weekly"
    case weekShort = "week_short"
    case month = "month"
    case monthly = "monthly"
    case monthShort = "month_short"
    case year = "year"
    case yearly = "yearly"
    case yearShort = "year_short"
    case annual = "annual"
    case annually = "annually"
    case annualShort = "annual_short"
    case freePrice = "free_price"
    case percent = "percent"
    case numDayZero = "num_day_zero"
    case numDayOne = "num_day_one"
    case numDayTwo = "num_day_two"
    case numDayFew = "num_day_few"
    case numDayMany = "num_day_many"
    case numDayOther = "num_day_other"
    case numWeekZero = "num_week_zero"
    case numWeekOne = "num_week_one"
    case numWeekTwo = "num_week_two"
    case numWeekFew = "num_week_few"
    case numWeekMany = "num_week_many"
    case numWeekOther = "num_week_other"
    case numMonthZero = "num_month_zero"
    case numMonthOne = "num_month_one"
    case numMonthTwo = "num_month_two"
    case numMonthFew = "num_month_few"
    case numMonthMany = "num_month_many"
    case numMonthOther = "num_month_other"
    case numYearZero = "num_year_zero"
    case numYearOne = "num_year_one"
    case numYearTwo = "num_year_two"
    case numYearFew = "num_year_few"
    case numYearMany = "num_year_many"
    case numYearOther = "num_year_other"
    case numDaysShort = "num_days_short"
    case numWeeksShort = "num_weeks_short"
    case numMonthsShort = "num_months_short"
    case numYearsShort = "num_years_short"
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum VariablesV2: String {

    case productCurrencyCode = "product.currency_code"
    case productCurrencySymbol = "product.currency_symbol"
    case productPeriodly = "product.periodly"
    case productPrice = "product.price"
    case productPricePerPeriod = "product.price_per_period"
    case productPricePerPeriodAbbreviated = "product.price_per_period_abbreviated"
    case productPricePerDay = "product.price_per_day"
    case productPricePerWeek = "product.price_per_week"
    case productPricePerMonth = "product.price_per_month"
    case productPricePerYear = "product.price_per_year"
    case productPeriod = "product.period"
    case productPeriodAbbreviated = "product.period_abbreviated"
    case productPeriodInDays = "product.period_in_days"
    case productPeriodInWeeks = "product.period_in_weeks"
    case productPeriodInMonths = "product.period_in_months"
    case productPeriodInYears = "product.period_in_years"
    case productPeriodWithUnit = "product.period_with_unit"
    case productOfferPrice = "product.offer_price"
    case productOfferPricePerDay = "product.offer_price_per_day"
    case productOfferPricePerWeek = "product.offer_price_per_week"
    case productOfferPricePerMonth = "product.offer_price_per_month"
    case productOfferPricePerYear = "product.offer_price_per_year"
    case productOfferPeriod = "product.offer_period"
    case productOfferPeriodAbbreviated = "product.offer_period_abbreviated"
    case productOfferPeriodInDays = "product.offer_period_in_days"
    case productOfferPeriodInWeeks = "product.offer_period_in_weeks"
    case productOfferPeriodInMonths = "product.offer_period_in_months"
    case productOfferPeriodInYears = "product.offer_period_in_years"
    case productOfferPeriodWithUnit = "product.offer_period_with_unit"
    case productOfferEndDate = "product.offer_end_date"
    case productSecondaryOfferPrice = "product.secondary_offer_price"
    case productSecondaryOfferPeriod = "product.secondary_offer_period"
    case productSecondaryOfferPeriodAbbreviated = "product.secondary_offer_period_abbreviated"
    case productRelativeDiscount = "product.relative_discount"
    case productStoreProductName = "product.store_product_name"

    // Countdown variables
    case countDaysWithZero = "count_days_with_zero"
    case countDaysWithoutZero = "count_days_without_zero"
    case countHoursWithZero = "count_hours_with_zero"
    case countHoursWithoutZero = "count_hours_without_zero"
    case countMinutesWithZero = "count_minutes_with_zero"
    case countMinutesWithoutZero = "count_minutes_without_zero"
    case countSecondsWithZero = "count_seconds_with_zero"
    case countSecondsWithoutZero = "count_seconds_without_zero"

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum FunctionsV2: String {

    case lowercase
    case uppercase
    case capitalize

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VariablesV2 {

    // swiftlint:disable:next cyclomatic_complexity function_body_length function_parameter_count
    func process(
        package: Package,
        locale: Locale,
        localizations: [String: String],
        discountRelativeToMostExpensivePerMonth: Double?,
        date: Date,
        promoOffer: PromotionalOffer?,
        countdownTime: CountdownTime?
    ) -> String {
        switch self {
        case .productCurrencyCode:
            return self.productCurrencyCode(package: package)
        case .productCurrencySymbol:
            return self.productCurrencySymbol(locale: locale)
        case .productPeriodly:
            return self.productPeriodly(package: package, localizations: localizations)
        case .productPrice:
            return self.productPrice(package: package)
        case .productPricePerPeriod:
            return self.productPricePerPeriod(package: package, localizations: localizations)
        case .productPricePerPeriodAbbreviated:
            return self.productPricePerPeriodAbbreviated(package: package, localizations: localizations)
        case .productPricePerDay:
            return self.productPricePerDay(package: package)
        case .productPricePerWeek:
            return self.productPricePerWeek(package: package)
        case .productPricePerMonth:
            return self.productPricePerMonth(package: package)
        case .productPricePerYear:
            return self.productPricePerYear(package: package)
        case .productPeriod:
            return self.productPeriod(package: package, localizations: localizations)
        case .productPeriodAbbreviated:
            return self.productPeriodAbbreviated(package: package, localizations: localizations)
        case .productPeriodInDays:
            return self.productPeriodInDays(package: package)
        case .productPeriodInWeeks:
            return self.productPeriodInWeeks(package: package)
        case .productPeriodInMonths:
            return self.productPeriodInMonths(package: package)
        case .productPeriodInYears:
            return self.productPeriodInYears(package: package)
        case .productPeriodWithUnit:
            return self.productPeriodWithUnit(package: package, localizations: localizations)
        case .productOfferPrice:
            return self.productOfferPrice(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferPricePerDay:
            return self.productOfferPricePerDay(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferPricePerWeek:
            return self.productOfferPricePerWeek(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferPricePerMonth:
            return self.productOfferPricePerMonth(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferPricePerYear:
            return self.productOfferPricePerYear(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferPeriod:
            return self.productOfferPeriod(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferPeriodAbbreviated:
            return self.productOfferPeriodAbbreviated(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferPeriodInDays:
            return self.productOfferPeriodInDays(package: package, promoOffer: promoOffer)
        case .productOfferPeriodInWeeks:
            return self.productOfferPeriodInWeeks(package: package, promoOffer: promoOffer)
        case .productOfferPeriodInMonths:
            return self.productOfferPeriodInMonths(package: package, promoOffer: promoOffer)
        case .productOfferPeriodInYears:
            return self.productOfferPeriodInYears(package: package, promoOffer: promoOffer)
        case .productOfferPeriodWithUnit:
            return self.productOfferPeriodWithUnit(
                package: package,
                localizations: localizations,
                promoOffer: promoOffer
            )
        case .productOfferEndDate:
            return self.productOfferEndDate(package: package, locale: locale, date: date, promoOffer: promoOffer)
        case .productSecondaryOfferPrice:
            return self.productSecondaryOfferPrice(package: package)
        case .productSecondaryOfferPeriod:
            return self.productSecondaryOfferPeriod(package: package)
        case .productSecondaryOfferPeriodAbbreviated:
            return self.productSecondaryOfferPeriodAbbreviated(package: package)
        case .productRelativeDiscount:
            return self.productRelativeDiscount(
                discountRelativeToMostExpensivePerMonth: discountRelativeToMostExpensivePerMonth,
                localizations: localizations
            )
        case .productStoreProductName:
            return self.productStoreProductName(package: package)
        case .countDaysWithZero:
            return self.countdownValue(countdownTime: countdownTime, format: .daysWithZero)
        case .countDaysWithoutZero:
            return self.countdownValue(countdownTime: countdownTime, format: .daysWithoutZero)
        case .countHoursWithZero:
            return self.countdownValue(countdownTime: countdownTime, format: .hoursWithZero)
        case .countHoursWithoutZero:
            return self.countdownValue(countdownTime: countdownTime, format: .hoursWithoutZero)
        case .countMinutesWithZero:
            return self.countdownValue(countdownTime: countdownTime, format: .minutesWithZero)
        case .countMinutesWithoutZero:
            return self.countdownValue(countdownTime: countdownTime, format: .minutesWithoutZero)
        case .countSecondsWithZero:
            return self.countdownValue(countdownTime: countdownTime, format: .secondsWithZero)
        case .countSecondsWithoutZero:
            return self.countdownValue(countdownTime: countdownTime, format: .secondsWithoutZero)
        }
    }

    func productCurrencyCode(package: Package) -> String {
        return package.storeProduct.currencyCode ?? ""
    }

    func productCurrencySymbol(locale: Locale) -> String {
        return locale.currencySymbol ?? ""
    }

    func productPrice(package: Package) -> String {
        return package.storeProduct.localizedPriceString
    }

    func productPricePerPeriod(package: Package, localizations: [String: String]) -> String {
        let price = package.storeProduct.localizedPriceString
        let period = self.productPeriod(package: package, localizations: localizations)

        return "\(price)/\(period)"
    }

    func productPricePerPeriodAbbreviated(package: Package, localizations: [String: String]) -> String {
        let price = package.storeProduct.localizedPriceString
        let periodAbbreviated = self.productPeriodAbbreviated(package: package, localizations: localizations)

        return "\(price)/\(periodAbbreviated)"
    }

    func productPeriodly(package: Package, localizations: [String: String]) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        // Ex: "3 months" will return as "3 months"
        if period.value > 1 {
            return self.productPeriodWithUnit(package: package, localizations: localizations)
        }

        let value: String
        switch period.unit {
        case .day:
            value = VariableLocalizationKey.daily.rawValue
        case .week:
            value = VariableLocalizationKey.weekly.rawValue
        case .month:
            value = VariableLocalizationKey.monthly.rawValue
        case .year:
            value = VariableLocalizationKey.yearly.rawValue
        }

        return localizations[value] ?? ""
    }

    func productPricePerDay(package: Package) -> String {
        return package.storeProduct.localizedPricePerDay ?? ""
    }

    func productPricePerWeek(package: Package) -> String {
        return package.storeProduct.localizedPricePerWeek ?? ""
    }

    func productPricePerMonth(package: Package) -> String {
        return package.storeProduct.localizedPricePerMonth ?? ""
    }

    func productPricePerYear(package: Package) -> String {
        return package.storeProduct.localizedPricePerYear ?? ""
    }

    func productPeriod(package: Package, localizations: [String: String]) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        if period.value > 1 {
            return self.productPeriodWithUnit(package: package, localizations: localizations)
        } else {
            return localizations[period.periodLocalizationKey] ?? ""
        }
    }

    func productPeriodAbbreviated(package: Package, localizations: [String: String]) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        if period.value > 1 {
            let localizedFormatKey: String
            switch period.unit {
            case .day:
                localizedFormatKey = VariableLocalizationKey.numDaysShort.rawValue
            case .week:
                localizedFormatKey = VariableLocalizationKey.numWeeksShort.rawValue
            case .month:
                localizedFormatKey = VariableLocalizationKey.numMonthsShort.rawValue
            case .year:
                localizedFormatKey = VariableLocalizationKey.numYearsShort.rawValue
            }

            guard let localizedFormat = localizations[localizedFormatKey] else {
                return ""
            }
            return String(format: localizedFormat, period.value)

        } else {
            guard let abbreviation = localizations[period.periodAbbreviatedLocalizationKey] else {
                return ""
            }

            return abbreviation
        }
    }

    func productPeriodInDays(package: Package) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        return "\(period.periodInUnit(unit: .day))"
    }

    func productPeriodInWeeks(package: Package) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        return "\(period.periodInUnit(unit: .week))"
    }

    func productPeriodInMonths(package: Package) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        return "\(period.periodInUnit(unit: .month))"
    }

    func productPeriodInYears(package: Package) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        return "\(period.periodInUnit(unit: .year))"
    }

    func productPeriodWithUnit(package: Package, localizations: [String: String]) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }

        guard let localizedFormat = localizations[period.unitPeriodLocalizationKey] else {
            return ""
        }

        return String(format: localizedFormat, period.value)
    }

    func productOfferPrice(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if isFree(discount) {
            return localizations[VariableLocalizationKey.freePrice.rawValue] ?? ""
        }

        return discount.localizedPriceString
    }

    func productOfferPricePerDay(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .day) {
            return ""
        }

        if isFree(discount) {
            return localizations[VariableLocalizationKey.freePrice.rawValue] ?? ""
        }

        guard let price = discount.pricePerDay, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    func productOfferPricePerWeek(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .week) {
            return ""
        }

        if isFree(discount) {
            return localizations[VariableLocalizationKey.freePrice.rawValue] ?? ""
        }

        guard let price = discount.pricePerWeek, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    func productOfferPricePerMonth(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .month) {
            return ""
        }

        if isFree(discount) {
            return localizations[VariableLocalizationKey.freePrice.rawValue] ?? ""
        }

        guard let price = discount.pricePerMonth, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    func productOfferPricePerYear(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .year) {
            return ""
        }

        if isFree(discount) {
            return localizations[VariableLocalizationKey.freePrice.rawValue] ?? ""
        }

        guard let price = discount.pricePerYear, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    func productOfferPeriod(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        let initialOffer = package.storeProduct.introductoryDiscount?.subscriptionPeriod
        guard let period = promoOffer?.discount.subscriptionPeriod ?? initialOffer else {
            return ""
        }

        return localizations[period.periodLocalizationKey] ?? ""
    }

    func productOfferPeriodAbbreviated(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        let initialOffer = package.storeProduct.introductoryDiscount?.subscriptionPeriod
        guard let period = promoOffer?.discount.subscriptionPeriod ?? initialOffer else {
            return ""
        }

        return localizations[period.periodAbbreviatedLocalizationKey] ?? ""
    }

    func productOfferPeriodInDays(package: Package, promoOffer: PromotionalOffer?) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .day) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .day))"
    }

    func productOfferPeriodInWeeks(package: Package, promoOffer: PromotionalOffer?) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .week) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .week))"
    }

    func productOfferPeriodInMonths(package: Package, promoOffer: PromotionalOffer?) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .month) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .month))"
    }

    func productOfferPeriodInYears(package: Package, promoOffer: PromotionalOffer?) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .year) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .year))"
    }

    func productOfferPeriodWithUnit(
        package: Package,
        localizations: [String: String],
        promoOffer: PromotionalOffer?
    ) -> String {
        let introOffer = package.storeProduct.introductoryDiscount?.subscriptionPeriod
        guard let period = promoOffer?.discount.subscriptionPeriod ?? introOffer else {
            return ""
        }

        guard let localizedFormat = localizations[period.unitPeriodLocalizationKey] else {
            return ""
        }

        return String(format: localizedFormat, period.value)
    }

    func productOfferEndDate(package: Package, locale: Locale, date: Date, promoOffer: PromotionalOffer?) -> String {
        guard let discount = promoOffer?.discount ?? package.storeProduct.introductoryDiscount else {
            return ""
        }

        let daysFromToday = discount.subscriptionPeriod.periodInUnit(unit: .day)

        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: daysFromToday, to: date)!

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = locale

        return formatter.string(from: futureDate)
    }

    func productSecondaryOfferPrice(package: Package) -> String {
        // Not implemented on this platform
        return ""
    }

    func productSecondaryOfferPeriod(package: Package) -> String {
        // Not implemented on this platform
        return ""
    }

    func productSecondaryOfferPeriodAbbreviated(package: Package) -> String {
        // Not implemented on this platform
        return ""
    }

    func productRelativeDiscount(
        discountRelativeToMostExpensivePerMonth: Double?,
        localizations: [String: String]
    ) -> String {
        guard let discountRelativeToMostExpensivePerMonth else {
            return ""
        }

        guard let localizedFormat = localizations[VariableLocalizationKey.percent.rawValue] else {
            return ""
        }

        let percent = Int((discountRelativeToMostExpensivePerMonth * 100).rounded(.toNearestOrAwayFromZero))
        return String(format: localizedFormat, percent)
    }

    func productStoreProductName(package: Package) -> String {
        return package.storeProduct.localizedTitle
    }

    enum CountdownFormat {
        case daysWithZero, daysWithoutZero
        case hoursWithZero, hoursWithoutZero
        case minutesWithZero, minutesWithoutZero
        case secondsWithZero, secondsWithoutZero
    }

    func countdownValue(countdownTime: CountdownTime?, format: CountdownFormat) -> String {
        guard let time = countdownTime else {
            return ""
        }

        switch format {
        case .daysWithZero:
            return String(format: "%02d", time.days)
        case .daysWithoutZero:
            return "\(time.days)"
        case .hoursWithZero:
            return String(format: "%02d", time.hours)
        case .hoursWithoutZero:
            return "\(time.hours)"
        case .minutesWithZero:
            return String(format: "%02d", time.minutes)
        case .minutesWithoutZero:
            return "\(time.minutes)"
        case .secondsWithZero:
            return String(format: "%02d", time.seconds)
        case .secondsWithoutZero:
            return "\(time.seconds)"
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension VariablesV2 {

    func canDiscountDisplay(_ discount: StoreProductDiscount, unit: SubscriptionPeriod.Unit) -> Bool {
        return unit.rawValue <= discount.subscriptionPeriod.unit.rawValue
    }

    func isFree(_ discount: StoreProductDiscount) -> Bool {
        switch discount.paymentMode {
        case .freeTrial:
            return true
        case .payAsYouGo, .payUpFront:
            return false
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension SubscriptionPeriod {

    var periodLocalizationKey: String {
        switch self.unit {
        case .day:
            return VariableLocalizationKey.day.rawValue
        case .week:
            return VariableLocalizationKey.week.rawValue
        case .month:
            return VariableLocalizationKey.month.rawValue
        case .year:
            return VariableLocalizationKey.year.rawValue
        }
    }

    var periodAbbreviatedLocalizationKey: String {
        switch self.unit {
        case .day:
            return VariableLocalizationKey.dayShort.rawValue
        case .week:
            return VariableLocalizationKey.weekShort.rawValue
        case .month:
            return VariableLocalizationKey.monthShort.rawValue
        case .year:
            return VariableLocalizationKey.yearShort.rawValue
        }
    }

    var unitPeriodLocalizationKey: String {
        switch (self.value, self.unit) {
        // Zero
        case (0, .day):
            return VariableLocalizationKey.numDayZero.rawValue
        case (0, .week):
            return VariableLocalizationKey.numWeekZero.rawValue
        case (0, .month):
            return VariableLocalizationKey.numMonthZero.rawValue
        case (0, .year):
            return VariableLocalizationKey.numYearZero.rawValue
        // One
        case (1, .day):
            return VariableLocalizationKey.numDayOne.rawValue
        case (1, .week):
            return VariableLocalizationKey.numWeekOne.rawValue
        case (1, .month):
            return VariableLocalizationKey.numMonthOne.rawValue
        case (1, .year):
            return VariableLocalizationKey.numYearOne.rawValue
        // Two
        case (2, .day):
            return VariableLocalizationKey.numDayTwo.rawValue
        case (2, .week):
            return VariableLocalizationKey.numWeekTwo.rawValue
        case (2, .month):
            return VariableLocalizationKey.numMonthTwo.rawValue
        case (2, .year):
            return VariableLocalizationKey.numYearTwo.rawValue
        // Few
        case (3...4, .day):
            return VariableLocalizationKey.numDayFew.rawValue
        case (3...4, .week):
            return VariableLocalizationKey.numWeekFew.rawValue
        case (3...4, .month):
            return VariableLocalizationKey.numMonthFew.rawValue
        case (3...4, .year):
            return VariableLocalizationKey.numYearFew.rawValue
        // Many
        case (5...10, .day):
            return VariableLocalizationKey.numDayMany.rawValue
        case (5...10, .week):
            return VariableLocalizationKey.numWeekMany.rawValue
        case (5...10, .month):
            return VariableLocalizationKey.numMonthMany.rawValue
        case (5...10, .year):
            return VariableLocalizationKey.numYearMany.rawValue
        // Other
        case (_, .day):
            return VariableLocalizationKey.numDayOther.rawValue
        case (_, .week):
            return VariableLocalizationKey.numWeekOther.rawValue
        case (_, .month):
            return VariableLocalizationKey.numMonthOther.rawValue
        case (_, .year):
            return VariableLocalizationKey.numYearOther.rawValue
        }
    }

    func periodInUnit(unit: SubscriptionPeriod.Unit) -> Int {
        return NSDecimalNumber(
            decimal: self.numberOfUnitsAs(unit: unit)
        ).rounding(accordingToBehavior: nil).intValue
    }

}

extension Locale {
    func currencySymbol(forCurrencyCode currencyCode: String) -> String? {
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode])
        return Locale(identifier: localeIdentifier).currencySymbol
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FunctionsV2 {

    func process(_ text: String) -> String {
        switch self {
        case .lowercase:
            return lowercase(text)
        case .uppercase:
            return uppercase(text)
        case .capitalize:
            return capitalize(text)
        }
    }

    func lowercase(_ text: String) -> String {
        return text.lowercased()
    }

    func uppercase(_ text: String) -> String {
        return text.uppercased()
    }

    func capitalize(_ text: String) -> String {
        return text.capitalized
    }

}

struct Whisker {

    // swiftlint:disable:next force_try
    private static let regex = try! NSRegularExpression(pattern: "\\{\\{\\s*(.*?)\\s*\\}\\}")

    let template: String
    let resolve: (String, String?) -> String?

    func render() -> String {
        var result = template
        let matches = Self.regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: template) else { continue }
            let expression = String(template[range])

            // Split the expression into variable and filter parts
            let parts = expression.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            let variablePart = parts[0]
            let functionPart = parts.count > 1 ? parts[1] : nil

            // Use the single callback to resolve the variable and apply the function
            if let resolvedValue = resolve(variablePart, functionPart) {
                // Replace the full match range in the result
                if let fullRange = Range(match.range, in: result) {
                    result.replaceSubrange(fullRange, with: "\(resolvedValue)")
                }
            }
        }

        return result
    }

}
