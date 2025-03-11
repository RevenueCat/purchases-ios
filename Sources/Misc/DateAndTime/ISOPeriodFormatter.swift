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
        ISODurationFormatter.string(from: period.isoDuration)
    }
}

extension SubscriptionPeriod {
    var isoDuration: ISODuration {
        ISODuration(
            years: unit == .year ? value : 0,
            months: unit == .month ? value : 0,
            weeks: unit == .week ? value : 0,
            days: unit == .day ? value : 0,
            hours: 0,
            minutes: 0,
            seconds: 0
        )
    }
}
