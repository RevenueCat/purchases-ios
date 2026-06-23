//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransferBehaviorAPI.swift
//

import Foundation
import RevenueCat_CustomEntitlementComputation

func checkTransferBehaviorAPI() {
    let transferToNewAppUserID: TransferBehavior = .transferToNewAppUserID
    let transferIfNoActiveSubscriptions: TransferBehavior = .transferIfNoActiveSubscriptions
    let keepWithOriginalAppUserID: TransferBehavior = .keepWithOriginalAppUserID

    let rawValue: String = keepWithOriginalAppUserID.rawValue
    let hash: Int = keepWithOriginalAppUserID.hash
    let isEqual: Bool = keepWithOriginalAppUserID.isEqual(TransferBehavior.keepWithOriginalAppUserID)
    let patternMatches: Bool = TransferBehavior.keepWithOriginalAppUserID ~= keepWithOriginalAppUserID

    print(
        transferToNewAppUserID,
        transferIfNoActiveSubscriptions,
        keepWithOriginalAppUserID,
        rawValue,
        hash,
        isEqual,
        patternMatches
    )
}
