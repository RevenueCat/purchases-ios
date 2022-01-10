//
//  SubscriptionPeriodAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 1/5/22.
//

import RevenueCat

var period: SubscriptionPeriod!

func checkSubscriptionPeriodAPI() {
    let period2 = SubscriptionPeriod(value: 0, unit: .day)

    let value: Int = period.value
    let unit: SubscriptionPeriod.Unit = period.unit

    print(value, unit)
}

func checkSubscriptionPeriodUnit() {
    let unit: SubscriptionPeriod.Unit = .unknown

    switch unit {
    case
            .unknown,
            .day,
            .week,
            .month,
            .year:
        break
    @unknown default:
        fatalError()
    }
}
