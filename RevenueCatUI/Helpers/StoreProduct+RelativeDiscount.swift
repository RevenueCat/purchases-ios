//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation
import RevenueCat

extension StoreProduct {

    /// Keeps display rounding out of relative discount calculations.
    var pricePerMonthForDiscount: Double? {
        guard let period = self.subscriptionPeriod else {
            return nil
        }

        let months = period.numberOfUnitsAs(unit: .month)
        guard months > 0 else {
            return nil
        }

        return NSDecimalNumber(decimal: self.price / months).doubleValue
    }

}
