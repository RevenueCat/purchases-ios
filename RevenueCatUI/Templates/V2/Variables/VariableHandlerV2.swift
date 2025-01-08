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

    let discountRelativeToMostExpensivePerMonth: Double?
    let showZeroDecimalPlacePrices: Bool
    let variableMapping: [String: String]
    let functionMapping: [String: String]
    let locale: Locale
    let localizations: [String: String]
    let packages: [Package]

    func processVariables(
        in text: String,
        with package: Package
    ) -> String {
        let whisker = Whisker(template: text) { variableRaw, functionRaw, params in
            let variable = self.findVariable(variableRaw)
            let function = functionRaw.flatMap { self.findFunction($0) }

            let processedVariable = variable?.process(
                package: package,
                locale: self.locale,
                localizations: self.localizations,
                discountRelativeToMostExpensivePerMonth: self.discountRelativeToMostExpensivePerMonth
            )

            return processedVariable.flatMap {
                function?.process($0) ?? $0
            }
        }

        return whisker.render()
    }
    
    private func findVariable(_ variableRaw: String) -> VariablesV2? {
        guard let originalVariable = VariablesV2(rawValue: variableRaw) else {
            
            let backSupportedVariableRaw = self.variableMapping[variableRaw]
            
            guard let backSupportedVariableRaw else {
                Logger.error("Paywall variable '\(variableRaw)' is not supported and no backward compatible replacement found.")
                return nil
            }
            
            guard let backSupportedVariable = VariablesV2(rawValue: backSupportedVariableRaw) else {
                Logger.error("Paywall variable '\(variableRaw)' is not supported and could not find backward compatible '\(backSupportedVariableRaw)'.")
                return nil
            }
            
            Logger.warning("Paywall variable '\(variableRaw)' is not supported. Using backward compatible '\(backSupportedVariableRaw)' instead.")
            return backSupportedVariable
        }
        
        return originalVariable
    }
    
    private func findFunction(_ functionRaw: String) -> FunctionsV2? {
        guard let originalFunction = FunctionsV2(rawValue: functionRaw) else {
            
            let backSupportedFunctionRaw = self.functionMapping[functionRaw]
            
            guard let backSupportedFunctionRaw else {
                Logger.error("Paywall function '\(functionRaw)' is not supported and no backward compatible replacement found.")
                return nil
            }
            
            guard let backSupportedFunction = FunctionsV2(rawValue: backSupportedFunctionRaw) else {
                Logger.error("Paywall variable '\(functionRaw)' is not supported and could not find backward compatible '\(backSupportedFunctionRaw)'.")
                return nil
            }
            
            Logger.warning("Paywall function '\(functionRaw)' is not supported. Using backward compatible '\(backSupportedFunction)' instead.")
            return backSupportedFunction
        }
        
        return originalFunction
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
    case productStoreProductName = "product.store_product_name"

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum FunctionsV2: String {

    case lowercase
    case uppercase
    case capitalize

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension VariablesV2 {

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func process(package: Package,
                 locale: Locale,
                 localizations: [String: String],
                 discountRelativeToMostExpensivePerMonth: Double?) -> String {
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
            return self.productOfferPrice(package: package, localizations: localizations)
        case .productOfferPricePerDay:
            return self.productOfferPricePerDay(package: package, localizations: localizations)
        case .productOfferPricePerWeek:
            return self.productOfferPricePerWeek(package: package, localizations: localizations)
        case .productOfferPricePerMonth:
            return self.productOfferPricePerMonth(package: package, localizations: localizations)
        case .productOfferPricePerYear:
            return self.productOfferPricePerYear(package: package, localizations: localizations)
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
            return self.productRelativeDiscount(
                discountRelativeToMostExpensivePerMonth: discountRelativeToMostExpensivePerMonth,
                localizations: localizations
            )
        case .productStoreProductName:
            return self.productStoreProductName(package: package)
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

    func productOfferPrice(package: Package, localizations: [String: String]) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if isFree(discount) {
            return localizations["free"] ?? ""
        }

        return discount.localizedPriceString
    }

    func productOfferPricePerDay(package: Package, localizations: [String: String]) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .day) {
            return ""
        }

        if isFree(discount) {
            return localizations["free"] ?? ""
        }

        guard let price = discount.pricePerDay, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    func productOfferPricePerWeek(package: Package, localizations: [String: String]) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .week) {
            return ""
        }

        if isFree(discount) {
            return localizations["free"] ?? ""
        }

        guard let price = discount.pricePerWeek, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    func productOfferPricePerMonth(package: Package, localizations: [String: String]) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .month) {
            return ""
        }

        if isFree(discount) {
            return localizations["free"] ?? ""
        }

        guard let price = discount.pricePerMonth, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }

    func productOfferPricePerYear(package: Package, localizations: [String: String]) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .year) {
            return ""
        }

        if isFree(discount) {
            return localizations["free"] ?? ""
        }

        guard let price = discount.pricePerYear, let formatter = package.storeProduct.priceFormatter else {
            return ""
        }

        return formatter.string(from: price as NSDecimalNumber) ?? ""
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
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .day) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .day))"
    }

    func productOfferPeriodInWeeks(package: Package) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .week) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .week))"
    }

    func productOfferPeriodInMonths(package: Package) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .month) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .month))"
    }

    func productOfferPeriodInYears(package: Package) -> String {
        guard let discount = package.storeProduct.introductoryDiscount else {
            return ""
        }

        if !canDiscountDisplay(discount, unit: .year) {
            return ""
        }

        return "\(discount.subscriptionPeriod.periodInUnit(unit: .year))"
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

    func productRelativeDiscount(
        discountRelativeToMostExpensivePerMonth: Double?,
        localizations: [String: String]
    ) -> String {
        guard let discountRelativeToMostExpensivePerMonth else {
            return ""
        }

        guard let localizedFormat = localizations["%d%%"] else {
            return ""
        }

        let percent = Int(discountRelativeToMostExpensivePerMonth * 100)
        return String(format: localizedFormat, percent)
    }

    func productStoreProductName(package: Package) -> String {
        return package.storeProduct.localizedTitle
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

import Foundation

struct Whisker {
    let template: String
    let resolve: (String, String?, [Any]?) -> String?

    func render() -> String {
        // Updated regex to allow dots in variable names
        let regex = try! NSRegularExpression(pattern: "\\{\\{\\s*([\\w\\.]+)(?:\\s*\\|\\s*([^\\}]+))?\\s*\\}\\}")
        var result = template
        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))

        for match in matches.reversed() {
            // Extract variable
            guard let variableRange = Range(match.range(at: 1), in: template) else { continue }
            let variable = String(template[variableRange])

            // Extract functions and parameters (optional)
            let functions: [(String, [Any]?)] = {
                if let range = Range(match.range(at: 2), in: template) {
                    let functionsString = String(template[range])
                    return functionsString.split(separator: "|").map { functionPart in
                        let parts = functionPart.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        let functionName = parts[0]
                        let params: [Any]? = parts.count > 1 ? parts[1].split(separator: ",").map { param in
                            let trimmed = param.trimmingCharacters(in: .whitespacesAndNewlines)
                            if let intVal = Int(trimmed) {
                                return intVal
                            } else if let doubleVal = Double(trimmed) {
                                return doubleVal
                            } else if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
                                return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                            } else {
                                return trimmed
                            }
                        } : nil
                        return (functionName, params)
                    }
                }
                return []
            }()

            // Resolve the value using the callback
            var resolvedValue: String? = resolve(variable, nil, nil)
            for (function, params) in functions {
                if let value = resolvedValue {
                    resolvedValue = resolve(value, function, params)
                }
            }

            // Replace the full match range in the result
            if let resolvedValue = resolvedValue, let fullRange = Range(match.range, in: result) {
                result.replaceSubrange(fullRange, with: resolvedValue)
            }
        }

        return result
    }
}

typealias TemplateFunction = (inout [String: Any], [Any]) -> Any

enum TemplateNode {
    case text(String)
    case variable(String)
    case functionChain(String, functions: [(name: String, arguments: [String])])
    case forLoop(variable: String, collection: String, body: [TemplateNode])
    case ifCondition(expression: String, body: [TemplateNode], elseBody: [TemplateNode])
    case packageBlock(packageId: String, body: [TemplateNode]) // Scoped block node
}

struct TemplateParser {
    func parse(template: String) -> [TemplateNode] {
        var nodes: [TemplateNode] = []
        let regex = try! NSRegularExpression(pattern: "\\{\\{.*?\\}\\}|\\{%.*?%\\}", options: [])

        
        var lastIndex = template.startIndex
        var stack: [(type: String, body: [TemplateNode], elseBody: [TemplateNode]?)] = []

        regex.enumerateMatches(in: template, range: NSRange(template.startIndex..<template.endIndex, in: template)) { match, _, _ in
            guard let match = match else { return }
            let range = Range(match.range, in: template)!
            
            if lastIndex < range.lowerBound {
                let text = String(template[lastIndex..<range.lowerBound])
                if stack.isEmpty {
                    nodes.append(.text(text))
                } else if stack[stack.count - 1].elseBody == nil {
                    stack[stack.count - 1].body.append(.text(text))
                } else {
                    stack[stack.count - 1].elseBody?.append(.text(text))
                }
            }
            
            let tag = String(template[range])
            if tag.hasPrefix("{%") && tag.hasSuffix("%}") {
                let content = tag.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if content.hasPrefix("if ") {
                    // Start an if-condition block
                    let condition = content.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    stack.append((type: "if:\(condition)", body: [], elseBody: nil))
                } else if content == "else" {
                    // Handle else block
                    if var last = stack.popLast(), last.type.starts(with: "if:") {
                        stack.append((type: last.type, body: last.body, elseBody: []))
                    }
                } else if content == "endif" {
                    // End the if-condition block
                    if let last = stack.popLast(), last.type.starts(with: "if:") {
                        let condition = last.type.dropFirst(3) // Remove "if:"
                        let ifBlock = TemplateNode.ifCondition(expression: String(condition), body: last.body, elseBody: last.elseBody ?? [])
                        if stack.isEmpty {
                            nodes.append(ifBlock)
                        } else if stack[stack.count - 1].elseBody == nil {
                            stack[stack.count - 1].body.append(ifBlock)
                        } else {
                            stack[stack.count - 1].elseBody?.append(ifBlock)
                        }
                    }
                } else if content.hasPrefix("package:") {
                    // Start a package block
                    let packageId = content.dropFirst(8).trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    stack.append((type: "package:\(packageId)", body: [], elseBody: nil))
                } else if content == "endpackage" {
                    // End the package block
                    if let last = stack.popLast(), last.type.starts(with: "package:") {
                        let packageId = last.type.split(separator: ":").dropFirst().joined(separator: ":")
                        let packageBlock = TemplateNode.packageBlock(packageId: packageId, body: last.body)
                        if stack.isEmpty {
                            nodes.append(packageBlock)
                        } else if stack[stack.count - 1].elseBody == nil {
                            stack[stack.count - 1].body.append(packageBlock)
                        } else {
                            stack[stack.count - 1].elseBody?.append(packageBlock)
                        }
                    }
                }
            } else if tag.hasPrefix("{{") && tag.hasSuffix("}}") {
                let content = tag.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespacesAndNewlines)

                if content.contains("|") {
                    // Handle piped functions
                    let parts = content.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                    let variable = parts.first!
                    let functions = parts.dropFirst().map { part -> (name: String, arguments: [String]) in
                        if let colonIndex = part.firstIndex(of: ":") {
                            let name = String(part[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                            let args = part[colonIndex...].dropFirst().split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                            return (name, args)
                        } else {
                            return (part, [])
                        }
                    }
                    if stack.isEmpty {
                        nodes.append(.functionChain(variable, functions: functions))
                    } else if stack[stack.count - 1].elseBody == nil {
                        stack[stack.count - 1].body.append(.functionChain(variable, functions: functions))
                    } else {
                        stack[stack.count - 1].elseBody?.append(.functionChain(variable, functions: functions))
                    }
                } else {
                    // Handle simple variables
                    if stack.isEmpty {
                        nodes.append(.variable(content))
                    } else if stack[stack.count - 1].elseBody == nil {
                        stack[stack.count - 1].body.append(.variable(content))
                    } else {
                        stack[stack.count - 1].elseBody?.append(.variable(content))
                    }
                }
            }
            
            lastIndex = range.upperBound
        }
        
        if lastIndex < template.endIndex {
            let text = String(template[lastIndex..<template.endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { // Only append non-empty text nodes
                if stack.isEmpty {
                    nodes.append(.text(text))
                } else if stack[stack.count - 1].elseBody == nil {
                    stack[stack.count - 1].body.append(.text(text))
                } else {
                    stack[stack.count - 1].elseBody?.append(.text(text))
                }
            }
        }
        
        return nodes
    }
}


struct TemplateRenderer {
    let functions: [String: TemplateFunction]
    let packageResolver: (String) -> [String: Any]?

    func render(nodes: [TemplateNode], context: inout [String: Any]) -> String {
        var output = ""

        for node in nodes {
            switch node {
            case .text(let text):
                output += text
            case .variable(let variable):
                if let value = resolveVariable(variable, in: context) {
                    output += "\(value)"
                }
            case .packageBlock(let packageId, let body):
                if let resolvedProduct = packageResolver(packageId) {
                    var scopedContext = context
                    scopedContext["product"] = resolvedProduct
                    output += render(nodes: body, context: &scopedContext)
                }
            case .functionChain(let variable, let functions):
                var value: Any = resolveVariable(variable, in: context) ?? variable
                for function in functions {
                    if let funcImplementation = self.functions[function.name] {
                        let args = function.arguments.map { arg in resolveVariable(arg, in: context) ?? arg }
                        value = funcImplementation(&context, [value] + args)
                    } else {
                        print("Warning: Function '\(function.name)' not found.")
                    }
                }
                output += "\(value)"
            case .forLoop(let variable, let collection, let body):
                if let items = resolveVariable(collection, in: context) as? [Any] {
                    for item in items {
                        var newContext = context
                        newContext[variable] = item
                        output += render(nodes: body, context: &newContext)
                    }
                }
            case .ifCondition(let expression, let body, let elseBody):
                if evaluate(expression: expression, context: context) {
                    output += render(nodes: body, context: &context)
                } else {
                    output += render(nodes: elseBody, context: &context)
                }
            }
        }

        return output
    }

    private func resolveVariable(_ variable: String, in context: [String: Any]) -> Any? {
        let keys = variable.split(separator: ".").map(String.init)
        var currentValue: Any? = context

        for key in keys {
            if let dictionary = currentValue as? [String: Any] {
                currentValue = dictionary[key]
            } else {
                return nil
            }
        }
        return currentValue
    }
    
    private func evaluate(expression: String, context: [String: Any]) -> Bool {
        let components = expression.split(separator: " ", maxSplits: 2)
        guard components.count == 3 else {
            print("Invalid expression format: \(expression)")
            return false
        }

        let lhs = resolveVariable(String(components[0]), in: context)
        let op = components[1]
        let rhs = components[2].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "'", with: "")

        switch op {
        case "==":
            if let lhsBool = lhs as? Bool {
                return lhsBool == (rhs == "true")
            }
            return "\(lhs ?? "")" == rhs
        case "!=":
            if let lhsBool = lhs as? Bool {
                return lhsBool != (rhs == "true")
            }
            return "\(lhs ?? "")" != rhs
        case ">":
            if let lhsInt = lhs as? Int, let rhsInt = Int(rhs) {
                return lhsInt > rhsInt
            }
        case "<":
            if let lhsInt = lhs as? Int, let rhsInt = Int(rhs) {
                return lhsInt < rhsInt
            }
        default:
            print("Unsupported operator: \(op)")
            return false
        }
        return false
    }

}

struct Liquid {
    private let parser: TemplateParser
    private let renderer: TemplateRenderer
    
    init(functions: [String: TemplateFunction] = [:], packageResolver: @escaping (String) -> [String: Any]?) {
        self.parser = TemplateParser()
        self.renderer = TemplateRenderer(functions: functions, packageResolver: packageResolver)
    }
    
    func render(template: String, context: inout [String: Any]) -> String {
            let nodes = parser.parse(template: template)
            let rawOutput = renderer.render(nodes: nodes, context: &context)
            return collapseEmptyLines(rawOutput) // Clean up empty lines
        }

        private func collapseEmptyLines(_ output: String) -> String {
            let lines = output.split(separator: "\n", omittingEmptySubsequences: false)
            var result = [String]()
            var previousWasEmpty = false

            for line in lines {
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    if !previousWasEmpty {
                        result.append("") // Add a single empty line
                    }
                    previousWasEmpty = true
                } else {
                    result.append(String(line))
                    previousWasEmpty = false
                }
            }

            return result.joined(separator: "\n")
        }
}
