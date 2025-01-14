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

    func localizedPrice(showZeroDecimalPlacePrices: Bool = false) -> String {
        if showZeroDecimalPlacePrices && isPriceEndingIn00Cents(self.storeProduct.localizedPriceString) {
            return formatAsZeroDecimalPlaces(self.storeProduct.localizedPriceString)
        } else {
            return self.storeProduct.localizedPriceString
        }
    }

    func localizedPricePerDay(showZeroDecimalPlacePrices: Bool = false) -> String {
        guard let price = self.storeProduct.localizedPricePerDay else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        if showZeroDecimalPlacePrices && isPriceEndingIn00Cents(price) {
            return formatAsZeroDecimalPlaces(price)
        } else {
            return price
        }

    }

    func localizedPricePerWeek(showZeroDecimalPlacePrices: Bool = false) -> String {
        guard let price = self.storeProduct.localizedPricePerWeek else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        if showZeroDecimalPlacePrices && isPriceEndingIn00Cents(price) {
            return formatAsZeroDecimalPlaces(price)
        } else {
            return price
        }

    }

    func localizedPricePerMonth(showZeroDecimalPlacePrices: Bool = false) -> String {
        guard let price = self.storeProduct.localizedPricePerMonth else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        if showZeroDecimalPlacePrices && isPriceEndingIn00Cents(price) {
            return formatAsZeroDecimalPlaces(price)
        }

        return price
    }

    func localizedIntroductoryOfferPrice(showZeroDecimalPlacePrices: Bool = false) -> String? {
        guard let price = self.storeProduct.introductoryDiscount?.localizedPriceString else {
            return self.storeProduct.introductoryDiscount?.localizedPriceString
        }

        if showZeroDecimalPlacePrices && isPriceEndingIn00Cents(price) {
            return formatAsZeroDecimalPlaces(price)
        }

        return price
    }

    var productName: String {
        return self.storeProduct.localizedTitle
    }

    func toPackageType(product: StoreProduct) -> PackageType? {
        guard let period = product.subscriptionPeriod else {
            return nil
        }

        switch (period.value, period.unit) {
        case (_, .day):
            return nil
        case (1, .week):
            return .weekly
        case (1, .month):
            return .monthly
        case (2, .month):
            return .twoMonth
        case (3, .month):
            return .threeMonth
        case (6, .month):
            return .sixMonth
        case (1, .year):
            return .annual
        default:
            return nil
        }
    }

    func periodNameOrIdentifier(_ locale: Locale) -> String {
        let packageType = toPackageType(product: self.storeProduct) ?? self.packageType
        return Localization.localized(packageType: packageType,
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

    func localizedPricePerPeriod(_ locale: Locale, showZeroDecimalPlacePrices: Bool = false) -> String {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.localizedPrice(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
        }

        let unit = Localization.abbreviatedUnitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPrice(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices))/\(unit)"
    }

    func localizedPricePerPeriodFull(_ locale: Locale, showZeroDecimalPlacePrices: Bool = false) -> String {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.localizedPrice(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
        }

        let unit = Localization.unitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPrice(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices))/\(unit)"
    }

    func localizedPriceAndPerMonth(_ locale: Locale, showZeroDecimalPlacePrices: Bool = false) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriod(locale, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
        } else {
            let unit = Localization.abbreviatedUnitLocalizedString(for: .init(value: 1, unit: .month),
                                                                   locale: locale)

            let price = self.localizedPricePerPeriod(locale, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
            let monthlyPrice = self.localizedPricePerMonth(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)

            return "\(price) (\(monthlyPrice)/\(unit))"
        }
    }

    func localizedPriceAndPerMonthFull(_ locale: Locale, showZeroDecimalPlacePrices: Bool = false) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriodFull(locale, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
        } else {
            let unit = Localization.unitLocalizedString(for: .init(value: 1, unit: .month),
                                                        locale: locale)

            let price = self.localizedPricePerPeriodFull(locale, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
            let monthlyPrice = self.localizedPricePerMonth(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)

            return "\(price) (\(monthlyPrice)/\(unit))"
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

    func isPriceEndingIn00Cents(_ priceString: String) -> Bool {
        guard let formatter = self.storeProduct.priceFormatter?.copy() as? NumberFormatter else {
            Logger.warning(Strings.no_price_format_price_formatter_unavailable)
            return false
        }

        guard let price = formatter.number(from: priceString)?.doubleValue else {
            Logger.warning(Strings.no_price_format_price_string_incompatible)
            return false
        }

        let roundedPrice = round(price * 100) / 100.0
        return roundedPrice.truncatingRemainder(dividingBy: 1) == 0
    }

    func formatAsZeroDecimalPlaces(_ priceString: String) -> String {
        guard let formatter = self.storeProduct.priceFormatter?.copy() as? NumberFormatter else {
            Logger.warning(Strings.no_price_round_price_formatter_nil)
            return priceString
        }

        guard let priceToRound = formatter.number(from: priceString)?.doubleValue else {
            Logger.warning(Strings.no_price_round_price_string_incompatible)
            return priceString
        }

        formatter.maximumFractionDigits = 0

        guard let roundedPriceString = formatter.string(from: NSNumber(value: priceToRound)) else {
            Logger.warning(Strings.no_price_round_formatter_failed)
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
