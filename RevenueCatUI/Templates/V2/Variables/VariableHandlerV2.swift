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

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct VariableHandlerV2 {
    
    let discountRelativeToMostExpensivePerMonth: Double?
    let showZeroDecimalPlacePrices: Bool
    
    func processVariables(
        in text: String,
        with package: Package,
        locale: Locale,
        localizations: [String: String]
    ) -> String {
        let whisker = Whisker(template: text) { variableRaw, functionRaw in
            let variable = VariablesV2(rawValue: variableRaw)
            let function = functionRaw.flatMap { FunctionsV2(rawValue: $0) }
            
            let processedVariable = variable?.process(package: package, locale: locale, localizations: localizations, discountRelativeToMostExpensivePerMonth: self.discountRelativeToMostExpensivePerMonth)
            
            return processedVariable.flatMap {
                function?.process($0) ?? $0
            }
        }
        
        return whisker.render()
    }
    
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

}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum FunctionsV2: String {
    
    case lowercase
    case uppercase
    case capitalize
    
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VariablesV2 {
    
    func process(package: Package, locale: Locale, localizations: [String: String], discountRelativeToMostExpensivePerMonth: Double?) -> String {
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
            return self.productOfferPrice(package: package)
        case .productOfferPricePerDay:
            return self.productOfferPricePerDay(package: package)
        case .productOfferPricePerWeek:
            return self.productOfferPricePerWeek(package: package)
        case .productOfferPricePerMonth:
            return self.productOfferPricePerMonth(package: package)
        case .productOfferPricePerYear:
            return self.productOfferPricePerYear(package: package)
        case .productOfferPeriod:
            return self.productOfferPeriod(package: package, localizations: localizations)
        case .productOfferPeriodAbbreviated:
            return self.productOfferPeriodAbbreviated(package: package, localizations: localizations)
        case .productOfferPeriodInDays:
            return self.productOfferPeriodInDays(package: package)
        case .productOfferPeriodInWeeks:
            return self.productOfferPeriodInWeeks(package: package)
        case .productOfferPeriodInMonths:
            return self.productOfferPeriodInMonths(package: package)
        case .productOfferPeriodInYears:
            return self.productOfferPeriodInYears(package: package)
        case .productOfferPeriodWithUnit:
            return self.productOfferPeriodWithUnit(package: package, localizations: localizations)
        case .productOfferEndDate:
            return self.productOfferEndDate(package: package)
        case .productSecondaryOfferPrice:
            return self.productSecondaryOfferPrice(package: package)
        case .productSecondaryOfferPeriod:
            return self.productSecondaryOfferPeriod(package: package)
        case .productSecondaryOfferPeriodAbbreviated:
            return self.productSecondaryOfferPeriodAbbreviated(package: package)
        case .productRelativeDiscount:
            return self.productRelativeDiscount(discountRelativeToMostExpensivePerMonth: discountRelativeToMostExpensivePerMonth, localizations: localizations)
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
        
        let value: String
        switch period.unit {
        case .day:
            value = "daily"
        case .week:
            value = "weekly"
        case .month:
            value = "monthly"
        case .year:
            value = "yearly"
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
        
        return localizations[period.periodLocalizationKey] ?? ""
    }
    
    func productPeriodAbbreviated(package: Package, localizations: [String: String]) -> String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return ""
        }
        
        return localizations[period.periodAbbreviatedLocalizationKey] ?? ""
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
        
        let thing = period.numberOfUnitsPer(unit: .week)
        print("thing: \(thing)")
        
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
    
    func productOfferPrice(package: Package) -> String {
        return package.storeProduct.introductoryDiscount?.localizedPriceString ?? ""
    }

    func productOfferPricePerDay(package: Package) -> String {
        return ""
    }

    func productOfferPricePerWeek(package: Package) -> String {
        return ""
    }

    func productOfferPricePerMonth(package: Package) -> String {
        return ""
    }

    func productOfferPricePerYear(package: Package) -> String {
        return ""
    }

    func productOfferPeriod(package: Package, localizations: [String: String]) -> String {
        guard let period =  package.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return ""
        }
        
        return localizations[period.periodLocalizationKey] ?? ""
    }

    func productOfferPeriodAbbreviated(package: Package, localizations: [String: String]) -> String {
        guard let period =  package.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return ""
        }
        
        return localizations[period.periodAbbreviatedLocalizationKey] ?? ""
    }

    func productOfferPeriodInDays(package: Package) -> String {
        guard let period =  package.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return ""
        }
        
        return "\(period.periodInUnit(unit: .day))"
    }

    func productOfferPeriodInWeeks(package: Package) -> String {
        guard let period =  package.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return ""
        }
        
        return "\(period.periodInUnit(unit: .week))"
    }

    func productOfferPeriodInMonths(package: Package) -> String {
        guard let period =  package.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return ""
        }
        
        return "\(period.periodInUnit(unit: .month))"
    }

    func productOfferPeriodInYears(package: Package) -> String {
        guard let period =  package.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return ""
        }
        
        return "\(period.periodInUnit(unit: .year))"
    }

    func productOfferPeriodWithUnit(package: Package, localizations: [String: String]) -> String {
        guard let period =  package.storeProduct.introductoryDiscount?.subscriptionPeriod else {
            return ""
        }
        
        guard let localizedFormat = localizations[period.unitPeriodLocalizationKey] else {
            return ""
        }
        
        return String(format: localizedFormat, period.value)
    }

    func productOfferEndDate(package: Package) -> String {
        return ""
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

    func productRelativeDiscount(discountRelativeToMostExpensivePerMonth: Double?, localizations: [String: String]) -> String {
        guard let discountRelativeToMostExpensivePerMonth else {
            return ""
        }
        
        guard let localizedFormat = localizations["%d%%"] else {
            return ""
        }
        
        let percent = Int(discountRelativeToMostExpensivePerMonth * 100)
        return String(format: localizedFormat, percent)
    }

}

extension SubscriptionPeriod {
    
    var periodLocalizationKey: String {
        switch self.unit {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        }
    }
    
    var periodAbbreviatedLocalizationKey: String {
        switch self.unit {
        case .day:
            return "d"
        case .week:
            return "wk"
        case .month:
            return "mo"
        case .year:
            return "yr"
        }
    }
    
    var unitPeriodLocalizationKey: String {
        if self.value == 1 {
            return "%d \(periodLocalizationKey)"
        } else {
            return "%d \(periodLocalizationKey)s"
        }
    }
    
    func periodInUnit(unit: SubscriptionPeriod.Unit) -> Int {
        return NSDecimalNumber(
            decimal: self.numberOfUnitsPer(unit: unit)
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
    let template: String
    let resolve: (String, String?) -> String?
    
    func render() -> String {
        let regex = try! NSRegularExpression(pattern: "\\{\\{\\s*(.*?)\\s*\\}\\}")
        var result = template
        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        
        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: template) else { continue }
            let expression = String(template[range])
            
            // Split the expression into variable and filter parts
            let parts = expression.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            let variable = parts[0]
            let filter = parts.count > 1 ? parts[1] : nil
            
            // Use the single callback to resolve the variable and apply the filter
            if let resolvedValue = resolve(variable, filter) {
                // Replace the full match range in the result
                if let fullRange = Range(match.range, in: result) {
                    result.replaceSubrange(fullRange, with: "\(resolvedValue)")
                }
            }
        }
        
        return result
    }
}
