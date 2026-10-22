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

/// Shares StoreKit 2 eligibility checks and results across product requests.
/// StoreKit determines eligibility per subscription group; whether an intro offer exists remains
/// a per-product decision. Invalidation clears completed results because eligibility can change
/// after a purchase or subscription expiration. Pending checks remain shared and cache their results
/// when they finish, so invalidation does not start overlapping StoreKit checks for the same group.
final class IntroEligibilityGroupCache: Sendable {

    private enum Entry {
        case pending(Task<Bool, Never>)
        case cached(Bool)
    }

    private let entriesByGroupID: Atomic<[String: Entry]> = .init([:])

    func clearCache() {
        self.entriesByGroupID.modify { entries in
            entries = entries.filter {
                if case .pending = $0.value { return true }
                return false
            }
        }
    }

    func eligibility(
        for groupID: String,
        log: IntroEligibilityLog,
        check: @escaping @Sendable (String) async -> Bool
    ) async -> Bool {
        let (entry, reused) = self.entriesByGroupID.modify { entries -> (Entry, Bool) in
            if let entry = entries[groupID] {
                return (entry, true)
            }

            let task = Task {
                let eligible = await log.eligibility(forSubscriptionGroup: groupID, check: check)
                // Only the shared task writes its result, before returning to any caller. A delayed
                // caller must not restore that result after a later invalidation or overwrite a new check.
                self.entriesByGroupID.modify { $0[groupID] = .cached(eligible) }
                return eligible
            }
            let entry = Entry.pending(task)
            entries[groupID] = entry
            return (entry, false)
        }

        switch entry {
        case .cached(let eligible):
            log.reusedEligibility(forSubscriptionGroup: groupID, isPending: false)
            return eligible
        case .pending(let task):
            if reused {
                log.reusedEligibility(forSubscriptionGroup: groupID, isPending: true)
            }
            return await task.value
        }
    }

}
