//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProductDiscount+CustomerCenter.swift
//
//  Created by Cesar de la Vega on 29/12/24.

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension StoreProductDiscountType {

    func localizedPricePerPeriodByPaymentMode(
        _ locale: Locale,
        localization: CustomerCenterConfigData.Localization
    ) -> String {
        let discountDuration = Localization.localizedDuration(for: self.subscriptionPeriod, locale: locale)

        switch self.paymentMode {
        case .freeTrial:
            return localization[.promoOfferButtonFreeTrial]
                .replacingOccurrences(of: "{{ duration }}", with: discountDuration)
        case .payAsYouGo:
            let discountedPeriods = SubscriptionPeriod(
                value: self.numberOfPeriods,
                unit: self.subscriptionPeriod.unit
            )
            let discountedDuration = Localization.localizedDuration(for: discountedPeriods, locale: locale)
            
            return localization[.promoOfferButtonRecurringDiscount]
                .replacingOccurrences(of: "{{ price }}", with: localizedPricePerPeriod(locale))
                .replacingOccurrences(of: "{{ duration }}", with: discountedDuration)
        case .payUpFront:
            return localization[.promoOfferButtonUpfrontPayment]
                .replacingOccurrences(of: "{{ duration }}", with: discountDuration)
                .replacingOccurrences(of: "{{ price }}", with: self.localizedPriceString)
        }
    }

    private func localizedPricePerPeriod(_ locale: Locale) -> String {
        let unit = Localization.abbreviatedUnitLocalizedString(for: self.subscriptionPeriod, locale: locale)
        return "\(self.localizedPriceString)/\(unit)"
    }
}
