//
//  ISOPeriodFormatter.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 6/30/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)

// TODO(post-migration): Switch public back to <> (nothing)
// TODO(post-migration): remove @objc since this is internal only
@objc(RCISOPeriodFormatter) public class ISOPeriodFormatter: NSObject {

    @objc public func string(fromProductSubscriptionPeriod period: SKProductSubscriptionPeriod) -> String {
        let unitString = self.period(fromUnit: period.unit)
        let stringResult = "P\(period.numberOfUnits)\(unitString)"
        return stringResult
    }

    private func period(fromUnit unit: SKProduct.PeriodUnit) -> String {
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
