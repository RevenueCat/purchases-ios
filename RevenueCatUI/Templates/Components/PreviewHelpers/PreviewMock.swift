//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockProduct.swift
//
//  Created by Josh Holtz on 11/14/24.

#if PAYWALL_COMPONENTS

#if DEBUG

import RevenueCat
import StoreKit

// swiftlint:disable identifier_name

enum PreviewMock {

    static var weeklyPackage: Package = .init(
        identifier: "weekly",
        packageType: .monthly,
        storeProduct: .init(sk1Product: Product(
            price: 3.99,
            unit: .week,
            localizedTitle: "Weekly"
        )),
        offeringIdentifier: "default"
    )

    static var monthlyPackage: Package = .init(
        identifier: "monthly",
        packageType: .monthly,
        storeProduct: .init(sk1Product: Product(
            price: 9.99,
            unit: .month,
            localizedTitle: "Monthly"
        )),
        offeringIdentifier: "default"
    )

    static var annualPackage: Package = .init(
        identifier: "annual",
        packageType: .annual,
        storeProduct: .init(sk1Product: Product(
            price: 99.99,
            unit: .year,
            localizedTitle: "Annual"
        )),
        offeringIdentifier: "default"
    )

}

extension PreviewMock {

    class Product: SK1Product, @unchecked Sendable {

        // swiftlint:disable:next nesting
        class MockSubPeriod: SKProductSubscriptionPeriod, @unchecked Sendable {

            let _unit: SKProduct.PeriodUnit

            init(unit: SKProduct.PeriodUnit) {
                self._unit = unit
            }

            override var numberOfUnits: Int {
                return 1
            }

            override var unit: SKProduct.PeriodUnit {
                return self._unit
            }

        }

        let _price: NSDecimalNumber
        let _unit: SKProduct.PeriodUnit
        let _localizedTitle: String

        init(price: NSDecimalNumber, unit: SKProduct.PeriodUnit, localizedTitle: String) {
            self._price = price
            self._unit = unit
            self._localizedTitle = localizedTitle
        }

        override var price: NSDecimalNumber {
            return self._price
        }

        override var subscriptionPeriod: SKProductSubscriptionPeriod? {
            return MockSubPeriod(unit: self._unit)
        }

        override var localizedTitle: String {
            return self._localizedTitle
        }

        override var priceLocale: Locale {
            return Locale(identifier: "en-US")
        }

    }

}

#endif

#endif
