//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo+CurrentEntitlement.swift
//
//  Created by Cesar de la Vega on 17/7/24.

import Foundation
import RevenueCat

extension CustomerInfo {

    func currentEntitlement() -> EntitlementInfo? {
        return self.entitlements
            .active
            .values
            .lazy
            .filter { $0.store == .appStore }
            .sorted { lhs, rhs in
                let lhsDateSeconds = lhs.expirationDate?.timeIntervalSince1970 ?? TimeInterval.greatestFiniteMagnitude
                let rhsDateSeconds = rhs.expirationDate?.timeIntervalSince1970 ?? TimeInterval.greatestFiniteMagnitude
                return lhsDateSeconds < rhsDateSeconds
            }
            .first
    }

}
