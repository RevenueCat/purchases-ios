//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@testable import RevenueCat

/// Holds individual StoreKit group checks, including repeated calls for the same group.
final class HeldSubscriptionGroupEligibilityCheck: Sendable {

    private struct State {
        var invocations: [String] = []
        var continuationsByIndex: [Int: CheckedContinuation<Bool, Never>] = [:]
        var completedAll = false
    }

    private let state = Atomic(State())
    let wasCancelled = Atomic(false)

    var invocations: [String] { self.state.value.invocations }

    func call(_ groupID: String) async -> Bool {
        let result = await withCheckedContinuation { continuation in
            let completedAll = self.state.modify {
                let index = $0.invocations.count
                $0.invocations.append(groupID)
                guard !$0.completedAll else { return true }
                $0.continuationsByIndex[index] = continuation
                return false
            }
            if completedAll { continuation.resume(returning: false) }
        }
        self.wasCancelled.value = Task.isCancelled
        return result
    }

    func complete(at index: Int, eligible: Bool) {
        let continuation = self.state.modify { $0.continuationsByIndex.removeValue(forKey: index) }
        continuation?.resume(returning: eligible)
    }

    func completeAll() {
        let continuations = self.state.modify {
            $0.completedAll = true
            let continuations = $0.continuationsByIndex
            $0.continuationsByIndex.removeAll()
            return continuations.values
        }
        continuations.forEach { $0.resume(returning: false) }
    }

}

/// Samples priority inside the shared worker without awaiting it from the test and escalating it accidentally.
final class PriorityRecordingGroupCheck: Sendable {

    let initialPriority = Atomic<TaskPriority?>(nil)
    let currentPriority = Atomic<TaskPriority?>(nil)
    let invocations = Atomic(0)
    private let released = Atomic(false)

    func call(_ groupID: String) async -> Bool {
        self.invocations.modify { $0 += 1 }
        self.initialPriority.value = Task.currentPriority
        while !self.released.value {
            self.currentPriority.value = Task.currentPriority
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        return true
    }

    func release() {
        self.released.value = true
    }

}
