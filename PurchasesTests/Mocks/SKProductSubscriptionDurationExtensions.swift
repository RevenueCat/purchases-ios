//
//  SKProductSubscriptionDurationExtensions.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 5/26/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import RevenueCat
import StoreKit

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)
extension SKProductSubscriptionPeriod {
    convenience init(numberOfUnits: Int,
                     unit: SK1Product.PeriodUnit) {
        self.init()
        self.setValue(numberOfUnits, forKey: "numberOfUnits")
        self.setValue(unit.rawValue, forKey: "unit")
    }
}
