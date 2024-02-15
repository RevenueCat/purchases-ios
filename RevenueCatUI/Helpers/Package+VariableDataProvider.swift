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

    var localizedPrice: String {
        return self.storeProduct.localizedPriceString
    }

    var localizedPricePerWeek: String {
        guard let price = self.storeProduct.localizedPricePerWeek else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
        }

        return price
    }

    var localizedPricePerMonth: String {
        guard let price = self.storeProduct.localizedPricePerMonth else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.localizedPriceString
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

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.localizedPrice
        }

        let unit = Localization.abbreviatedUnitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPrice)/\(unit)"
    }

    func localizedPricePerPeriodFull(_ locale: Locale) -> String {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.localizedPrice
        }

        let unit = Localization.unitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPrice)/\(unit)"
    }

    func localizedPriceAndPerMonth(_ locale: Locale) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriod(locale)
        } else {
            let unit = Localization.abbreviatedUnitLocalizedString(for: .init(value: 1, unit: .month),
                                                                   locale: locale)
            return "\(self.localizedPricePerPeriod(locale)) (\(self.localizedPricePerMonth)/\(unit))"
        }
    }

    func localizedPriceAndPerMonthFull(_ locale: Locale) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriodFull(locale)
        } else {
            let unit = Localization.unitLocalizedString(for: .init(value: 1, unit: .month),
                                                        locale: locale)
            return "\(self.localizedPricePerPeriodFull(locale)) (\(self.localizedPricePerMonth)/\(unit))"
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
