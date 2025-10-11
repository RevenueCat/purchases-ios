//
//  PurchaseResultComparator.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 10/10/25.
//

import Foundation
@_spi(Internal) import RevenueCat

enum PurchaseResultComparator {
    static func compare(
        _ lhs: PurchaseResultData?,
        _ rhs: PurchaseResultData
    ) -> Bool {
        return lhs?.transaction == rhs.transaction &&
            lhs?.userCancelled == rhs.userCancelled &&
            lhs?.customerInfo == rhs.customerInfo
    }
}
