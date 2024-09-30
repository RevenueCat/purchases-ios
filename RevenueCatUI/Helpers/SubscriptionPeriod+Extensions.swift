//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionPeriod+Extensions.swift
//
//  Created by Cesar de la Vega on 25/9/24.

import Foundation
import RevenueCat

extension SubscriptionPeriod {

    var durationTitle: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        var components = DateComponents()

        switch self.unit {
        case .day:
            components.day = self.value
        case .week:
            components.weekOfMonth = self.value
        case .month:
            components.month = self.value
        case .year:
            components.year = self.value
        default:
            return "\(self.value)"
        }

        return formatter.string(from: components) ?? "\(self.value)"
    }

}
