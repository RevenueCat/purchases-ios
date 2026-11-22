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
        return formatPrice(self.storeProduct.localizedPriceString,
                           showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
    }

    func localizedPricePerDay(showZeroDecimalPlacePrices: Bool = false) -> String {
        return self.localizedPricePerDay(
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: .autoupdatingCurrent
        )
    }

    func localizedPricePerDay(showZeroDecimalPlacePrices: Bool, deviceLocale: Locale) -> String {
        return self.formatPricePerPeriod(
            self.storeProduct.pricePerDay,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: deviceLocale
        )
    }

    func localizedPricePerWeek(showZeroDecimalPlacePrices: Bool = false) -> String {
        return self.localizedPricePerWeek(
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: .autoupdatingCurrent
        )
    }

    func localizedPricePerWeek(showZeroDecimalPlacePrices: Bool, deviceLocale: Locale) -> String {
        return self.formatPricePerPeriod(
            self.storeProduct.pricePerWeek,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: deviceLocale
        )
    }

    func localizedPricePerMonth(showZeroDecimalPlacePrices: Bool = false) -> String {
        return self.localizedPricePerMonth(
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: .autoupdatingCurrent
        )
    }

    func localizedPricePerMonth(showZeroDecimalPlacePrices: Bool, deviceLocale: Locale) -> String {
        return self.formatPricePerPeriod(
            self.storeProduct.pricePerMonth,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: deviceLocale
        )
    }

    func localizedPricePerYear(showZeroDecimalPlacePrices: Bool = false) -> String {
        return self.localizedPricePerYear(
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: .autoupdatingCurrent
        )
    }

    func localizedPricePerYear(showZeroDecimalPlacePrices: Bool, deviceLocale: Locale) -> String {
        return self.formatPricePerPeriod(
            self.storeProduct.pricePerYear,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices,
            deviceLocale: deviceLocale
        )
    }

    func localizedIntroductoryOfferPrice(showZeroDecimalPlacePrices: Bool = false) -> String? {
        guard let price = self.storeProduct.introductoryDiscount?.localizedPriceString else {
            return self.storeProduct.introductoryDiscount?.localizedPriceString
        }
        return formatPrice(price, showZeroDecimalPlacePrices: showZeroDecimalPlacePrices)
    }

    /// Formats a per-period price (e.g. price per month) so it looks like `localizedPriceString`.
    ///
    /// `StoreProduct.priceFormatter` can use a different locale than `localizedPriceString`
    /// (for example, device language `fr` with a US storefront), which makes per-period prices
    /// render with different separators and currency placement than the full price.
    /// When that happens, this falls back to the device locale if it reproduces `localizedPriceString`.
    private func formatPricePerPeriod(
        _ price: NSDecimalNumber?,
        showZeroDecimalPlacePrices: Bool,
        deviceLocale: Locale
    ) -> String {
        guard let price = price?.decimalValue, let formatter = self.storeProduct.priceFormatter else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        let formatterMatchingDisplayedPrice = self.formatterMatchingLocalizedPriceString(
            formatter,
            deviceLocale: deviceLocale
        )

        return formatterMatchingDisplayedPrice.formattedPriceStrippingTrailingZerosIfNeeded(
            price,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
        ) ?? self.storeProduct.localizedPriceString
    }

    private func formatterMatchingLocalizedPriceString(
        _ formatter: NumberFormatter,
        deviceLocale: Locale
    ) -> NumberFormatter {
        let displayedPrice = self.storeProduct.localizedPriceString
        let fullPrice = self.storeProduct.price as NSDecimalNumber

        guard formatter.string(from: fullPrice) != displayedPrice,
              formatter.locale != deviceLocale,
              let copy = formatter.copy() as? NumberFormatter else {
            return formatter
        }

        copy.locale = deviceLocale
        return copy.string(from: fullPrice) == displayedPrice ? copy : formatter
    }

    private func formatPrice(_ priceString: String, showZeroDecimalPlacePrices: Bool) -> String {
        guard let formatter = self.storeProduct.priceFormatter else {
            return priceString
        }
        return formatter.formattedPriceStrippingTrailingZerosIfNeeded(
            from: priceString,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
        )
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

    func localizedRelativeDiscount(_ discount: Decimal?, _ locale: Locale) -> String? {
        guard let discount else { return nil }

        return Localization.localized(discount: discount, locale: locale)
    }

}

// MARK: - Private

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
