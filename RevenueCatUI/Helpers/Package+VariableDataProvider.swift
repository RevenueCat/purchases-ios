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
        if showZeroDecimalPlacePrices {
            return roundAndTruncatePrice(self.storeProduct.localizedPriceString)
        } else {
            return self.storeProduct.localizedPriceString
        }
    }

    func localizedPricePerWeek(showZeroDecimalPlacePrices: Bool = false) -> String {
        guard let price = self.storeProduct.localizedPricePerWeek else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        if showZeroDecimalPlacePrices && priceEndsIn99or00Cents(price) {
            return roundAndTruncatePrice(price)
        } else {
            return price
        }

    }

    func localizedPricePerMonth(showZeroDecimalPlacePrices: Bool = false) -> String {
        guard let price = self.storeProduct.localizedPricePerMonth else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        if showZeroDecimalPlacePrices && priceEndsIn99or00Cents(price) {
            return roundAndTruncatePrice(price)
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
            // swiftlint:disable:next line_length
            return "\(self.localizedPricePerPeriod(locale, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)) (\(self.localizedPricePerMonth(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices))/\(unit))"
        }
    }

    func localizedPriceAndPerMonthFull(_ locale: Locale, showZeroDecimalPlacePrices: Bool = false) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriodFull(locale, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
        } else {
            let unit = Localization.unitLocalizedString(for: .init(value: 1, unit: .month),
                                                        locale: locale)

            // swiftlint:disable:next line_length
            return "\(self.localizedPricePerPeriodFull(locale, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)) (\(self.localizedPricePerMonth(showZeroDecimalPlacePrices: showZeroDecimalPlacePrices))/\(unit))"
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

    func priceEndsIn99or00Cents(_ priceString: String) -> Bool {
        guard let formatter = self.storeProduct.priceFormatter?.copy() as? NumberFormatter else {
            Logger.warning(Strings.no_price_format_priceFormatter_unavailable)
            return false
        }

        guard let price = formatter.number(from: priceString)?.doubleValue else {
            Logger.warning(Strings.no_price_format_priceString_incompatible)
            return false
        }

        let roundedCents = Int(price * 100) % 100
        return roundedCents == 99 || roundedCents == 0
    }

    func roundAndTruncatePrice(_ priceString: String) -> String {
        guard let formatter = self.storeProduct.priceFormatter?.copy() as? NumberFormatter else {
            Logger.warning(Strings.no_price_round_priceFormatter_nil)
            return priceString
        }

        guard let priceToRound = formatter.number(from: priceString)?.doubleValue else {
            Logger.warning(Strings.no_price_round_priceString_incompatible)
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
