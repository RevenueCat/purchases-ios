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

/// Shares SK2 introductory offer eligibility checks across products in the same subscription group.
/// The caching wrapper controls invalidation of both product and group results.
/// Invalidated checks still finish for existing callers, but cannot populate the cache or serve new callers.
final class SubscriptionGroupIntroEligibilityCache: Sendable {

    private enum Entry {
        case pending(id: UUID, task: Task<Bool, Never>)
        case cached(Bool)
    }

    private let entriesByGroupID: Atomic<[String: Entry]> = .init([:])

    func clearCache() {
        self.entriesByGroupID.modify { $0.removeAll() }
    }

    func eligibility(
        for groupID: String,
        log: IntroEligibilityLog,
        check: @escaping @Sendable (String) async -> Bool
    ) async -> Bool {
        let entry = self.entriesByGroupID.modify { entries -> Entry in
            if let entry = entries[groupID] {
                return entry
            }

            let id = UUID()
            let task = Task {
                let eligible = await log.eligibility(forSubscriptionGroup: groupID, check: check)
                // Only the current check may publish. Clearing the cache does not cancel this task,
                // but its result must not restore an invalidated entry or replace a newer check.
                self.entriesByGroupID.modify { entries in
                    guard case .pending(let currentID, _) = entries[groupID], currentID == id else { return }
                    entries[groupID] = .cached(eligible)
                }
                return eligible
            }
            let entry = Entry.pending(id: id, task: task)
            entries[groupID] = entry
            return entry
        }

        switch entry {
        case .cached(let eligible):
            return eligible
        case .pending(_, let task):
            return await task.value
        }
    }

}
