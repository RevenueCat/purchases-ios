//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ISOPeriodFormatter.swift
//
//  Created by Joshua Liebowitz on 6/30/21.
//

import Foundation
import StoreKit

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)

class ISOPeriodFormatter {

    func string(fromProductSubscriptionPeriod period: SKProductSubscriptionPeriod) -> String {
        let unitString = self.period(fromUnit: period.unit)
        let stringResult = "P\(period.numberOfUnits)\(unitString)"
        return stringResult
    }

    private func period(fromUnit unit: LegacySKProduct.PeriodUnit) -> String {
        switch unit {
        case .day:
            return "D"
        case .week:
            return "W"
        case .month:
            return "M"
        case .year:
            return "Y"
        @unknown default:
            fatalError("New SKProduct.PeriodUnit \(unit) unaccounted for")
        }
    }

}
