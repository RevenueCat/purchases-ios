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
}
