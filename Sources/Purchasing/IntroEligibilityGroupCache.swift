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

/// Shares StoreKit 2 eligibility checks and results within one eligibility-cache generation.
/// StoreKit determines eligibility per subscription group; whether an intro offer exists remains
/// a per-product decision. The owner replaces this cache on invalidation because eligibility can
/// change after a purchase or subscription expiration, including from ineligible to eligible.
actor IntroEligibilityGroupCache {

    private enum Entry {
        case pending(Task<Bool, Never>)
        case cached(Bool)
    }

    private var entriesByGroupID: [String: Entry] = [:]

    func eligibility(
        for groupID: String,
        log: IntroEligibilityLog,
        check: @escaping @Sendable (String) async -> Bool
    ) async -> Bool {
        switch self.entriesByGroupID[groupID] {
        case .cached(let eligible):
            log.reusedEligibility(forSubscriptionGroup: groupID, isPending: false)
            return eligible
        case .pending(let task):
            log.reusedEligibility(forSubscriptionGroup: groupID, isPending: true)
            return await task.value
        case nil:
            let task = Task { await log.eligibility(forSubscriptionGroup: groupID, check: check) }
            self.entriesByGroupID[groupID] = .pending(task)
            let eligible = await task.value
            self.entriesByGroupID[groupID] = .cached(eligible)
            return eligible
        }
    }

}
