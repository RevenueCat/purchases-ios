//
//  ISOPeriodFormatter.swift
//  Purchases
//
//  Created by Andrés Boedo on 5/22/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)
@objc(RCISOPeriodFormatter) internal class ISOPeriodFormatter: NSObject {
    
    @objc internal func string(fromProductSubscriptionPeriod period: SKProductSubscriptionPeriod) -> String {
        let unitString = self.periodFromUnit(unit: period.unit)
        return "P\(period.numberOfUnits)\(unitString)"
    }
}

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)
private extension ISOPeriodFormatter {
    
    func periodFromUnit(unit: SKProduct.PeriodUnit) -> String {
        switch unit {
        case .day: return "D"
        case .month: return "M"
        case .week: return "W"
        case .year: return "Y"
        default: fatalError()
        }
    }
}
