//
//  Extensions.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/26/21.
//

import Foundation
import RevenueCat
import StoreKit

/* The `Package` class needs to be identifiable to work with a List */

extension Package: Identifiable {
    public var id: String { self.identifier }
}

/* Some methods to make displaying subscription terms easier */

extension Package {
    func terms(for package: Package) -> String {
        if let intro = package.product.introductoryPrice {
            if intro.price == 0 {
                return "\(intro.subscriptionPeriod.periodTitle()) free trial"
            } else {
                return  "\(package.localizedIntroductoryPriceString) for \(intro.subscriptionPeriod.periodTitle())"
            }
        } else {
            return "Unlocks Premium"
        }
    }
}

extension SKProductSubscriptionPeriod {
    var durationTitle: String {
        switch self.unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "Unknown"
        }
    }
    
    func periodTitle() -> String {
        let periodString = "\(self.numberOfUnits) \(self.durationTitle)"
        let pluralized = self.numberOfUnits > 1 ?  periodString + "s" : periodString
        return pluralized
    }
}
