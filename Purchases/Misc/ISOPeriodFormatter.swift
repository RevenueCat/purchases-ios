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
enum ISOPeriodFormatter {

    static func string(fromProductSubscriptionPeriod period: SubscriptionPeriod) -> String {
        let unitString = Self.period(fromUnit: period.unit)
        let stringResult = "P\(period.value)\(unitString)"
        return stringResult
    }

    private static func period(fromUnit unit: SubscriptionPeriod.Unit) -> String {
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
