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

/// Shares SK2 eligibility checks across products in the same subscription group.
/// The caching wrapper controls invalidation of both product results and completed group results.
/// Pending checks remain shared across invalidation and store their result when they finish.
final class SubscriptionGroupEligibilityCache: Sendable {

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
                // Publish once before returning to any waiter. Delayed waiters cannot restore an
                // invalidated result or overwrite the answer from a newer check.
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
