//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Package+VariableDataProvider.swift

import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension Package: VariableDataProvider {

    var applicationName: String {
        return Bundle.main.applicationDisplayName
    }

    var packageIdentifier: String {
        return self.identifier
    }


    func localizedPriceFor(context: VariableHandler.Context?) -> String {
        if shouldRoundAndTruncatePrices(context: context) {
            return roundAndTruncatePrice(self.storeProduct.localizedPriceString)
        } else {
            return self.storeProduct.localizedPriceString
        }
    }

    func localizedPricePerWeek(context: VariableHandler.Context? = nil) -> String {
        guard let price = self.storeProduct.localizedPricePerWeek else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        if shouldRoundAndTruncatePrices(context: context) {
            return roundAndTruncatePrice(price, onlyIf99or00: true)
        }

        return price
    }

    func localizedPricePerMonth(context: VariableHandler.Context? = nil) -> String {
        guard let price = self.storeProduct.localizedPricePerMonth else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        if shouldRoundAndTruncatePrices(context: context) {
            return roundAndTruncatePrice(price, onlyIf99or00: true)
        }

        return price
    }

    var localizedIntroductoryOfferPrice: String? {
        return self.storeProduct.introductoryDiscount?.localizedPriceString
    }

    var productName: String {
        return self.storeProduct.localizedTitle
    }

    func periodNameOrIdentifier(_ locale: Locale) -> String {
        return Localization.localized(packageType: self.packageType,
                                      locale: locale) ?? self.identifier
    }

    func periodNameAbbreviation(_ locale: Locale) -> String? {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return nil
        }

        return Localization.abbreviatedUnitLocalizedString(for: period, locale: locale)
    }

    func periodLength(_ locale: Locale) -> String? {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return nil
        }

        return Localization.unitLocalizedString(for: period, locale: locale)
    }

    func subscriptionDuration(_ locale: Locale) -> String? {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.periodNameOrIdentifier(locale)
        }

        return Localization.localizedDuration(for: period, locale: locale)
    }

    func normalizedSubscriptionDuration(_ locale: Locale) -> String? {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.periodNameOrIdentifier(locale)
        }

        return Localization.localizedDuration(for: period.normalized, locale: locale)
    }

    func introductoryOfferDuration(_ locale: Locale) -> String? {
        return self.introDuration(locale)
    }

    func localizedPricePerPeriod(_ locale: Locale, context: VariableHandler.Context? = nil) -> String {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.localizedPriceFor(context: context)
        }

        let unit = Localization.abbreviatedUnitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPriceFor(context: context))/\(unit)"
    }

    func localizedPricePerPeriodFull(_ locale: Locale, context: VariableHandler.Context? = nil) -> String {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.localizedPriceFor(context: context)
        }

        let unit = Localization.unitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPriceFor(context: context))/\(unit)"
    }

    func localizedPriceAndPerMonth(_ locale: Locale, context: VariableHandler.Context? = nil) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriod(locale, context: context)
        } else {
            let unit = Localization.abbreviatedUnitLocalizedString(for: .init(value: 1, unit: .month),
                                                                   locale: locale)
            return "\(self.localizedPricePerPeriod(locale, context: context)) (\(self.localizedPricePerMonth(context: context))/\(unit))"
        }
    }

    func localizedPriceAndPerMonthFull(_ locale: Locale, context: VariableHandler.Context? = nil) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriodFull(locale)
        } else {
            let unit = Localization.unitLocalizedString(for: .init(value: 1, unit: .month),
                                                        locale: locale)
            return "\(self.localizedPricePerPeriodFull(locale, context: context)) (\(self.localizedPricePerMonth(context: context))/\(unit))"
        }
    }

    func localizedRelativeDiscount(_ discount: Double?, _ locale: Locale) -> String? {
        guard let discount else { return nil }

        return Localization.localized(discount: discount, locale: locale)
    }

}


// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension Package {
    func shouldRoundAndTruncatePrices(context: VariableHandler.Context?) -> Bool {

        guard let context else {
            Logger.warning("Cound not consider price rounding because context is nil.")
            return false
        }

        guard !context.integerPriceCountries.isEmpty else {
            return false
        }

        guard let countryCode = Purchases.shared.storeFrontCountryCode else {
            Logger.warning("Cound not consider price because storeFrontCountryCode is nil.")
            return false
        }

        return context.integerPriceCountries.contains(countryCode)
    }

    func roundAndTruncatePrice(_ priceString: String, onlyIf99or00: Bool = false) -> String {
        guard let formatter = self.storeProduct.priceFormatter?.copy() as? NumberFormatter else {
            Logger.warning("Cound not round price because priceFormatter is nil.")
            return priceString
        }

        guard let priceToRound = formatter.number(from: priceString)?.doubleValue else {
            Logger.warning("Cound not round price because localizedPriceString is incompatible.")
            return priceString
        }

        // exit early if conditions not met
        if onlyIf99or00 {
            let fractionalPart = priceToRound.truncatingRemainder(dividingBy: 1)
            guard fractionalPart == 0.99 || fractionalPart == 0.00 else {
                return priceString
            }
        }

        formatter.maximumFractionDigits = 0

        guard let roundedPriceString = formatter.string(from: NSNumber(value: priceToRound)) else {
            Logger.warning("Cound not round price because formatter failed to round price.")
            return priceString
        }

        return roundedPriceString
    }
}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension Package {

    var isSubscription: Bool {
        return self.storeProduct.productCategory == .subscription
    }

    var isMonthly: Bool {
        return self.storeProduct.subscriptionPeriod == SubscriptionPeriod(value: 1, unit: .month)
    }

    func introDuration(_ locale: Locale) -> String? {
        guard let discount = self.storeProduct.introductoryDiscount else { return nil }

        return Localization.localizedDuration(for: discount.subscriptionPeriod, locale: locale)
    }

}

private extension Bundle {

    var applicationDisplayName: String {
        return self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? self.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? ""
    }

}

private extension SubscriptionPeriod {

    var normalized: Self {
        switch self.unit {
        case .year:
            return .init(value: self.value * 12, unit: .month)

        default:
            // No other normalization is needed
            return self
        }
    }

}
