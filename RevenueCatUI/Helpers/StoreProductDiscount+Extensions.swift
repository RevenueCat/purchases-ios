//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProductDiscount+Extensions.swift
//
//  Created by Cesar de la Vega on 25/9/24.

import Foundation
@_spi(Internal) import RevenueCat

@_spi(Internal) extension StoreProductDiscountType {

    var discountedPeriodsWithUnit: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        var components = DateComponents()

        switch self.subscriptionPeriod.unit {
        case .day:
            components.day = self.numberOfPeriods
        case .week:
            components.weekOfMonth = self.numberOfPeriods
        case .month:
            components.month = self.numberOfPeriods
        case .year:
            components.year = self.numberOfPeriods
        default:
            return "\(self.numberOfPeriods)"
        }

        return formatter.string(from: components) ?? "\(self.numberOfPeriods)"
    }

    func localizedPricePerPeriodByPaymentMode(_ locale: Locale) -> String {
        let discountDuration = self.subscriptionPeriod.durationTitle

        let localizedBundle = Localization.localizedBundle(locale)

        switch self.paymentMode {
        case .freeTrial:
            // 3 months for free
            let format = localizedBundle.localizedString(forKey: "free_trial_period", value: "%@ for free", table: nil)

            return String(format: format, discountDuration)
        case .payAsYouGo:
            // $0.99/month for 3 months
            let format =
            localizedBundle.localizedString(forKey: "pay_as_you_go_period", value: "%@ during %@", table: nil)
            return String(format: format, localizedPricePerPeriod(locale), discountedPeriodsWithUnit)
        case .payUpFront:
            // 3 months for $0.99
            let format = localizedBundle.localizedString(forKey: "pay_up_front_period", value: "%@ for %@", table: nil)
            return String(format: format, discountDuration, self.localizedPriceString)
        }
    }

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        let unit = Localization.abbreviatedUnitLocalizedString(for: self.subscriptionPeriod, locale: locale)
        return "\(self.localizedPriceString)/\(unit)"
    }
}
