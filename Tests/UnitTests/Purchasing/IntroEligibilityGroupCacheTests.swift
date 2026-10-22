//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Nimble
@testable import RevenueCat
import XCTest

class IntroEligibilityGroupCacheTests: TestCase {

    func testCachesBothEligibleAndIneligibleResults() async {
        for eligible in [true, false] {
            let cache = IntroEligibilityGroupCache()
            let invocations = Atomic(0)
            let check: @Sendable (String) async -> Bool = { groupID in
                expect(groupID) == "group"
                invocations.modify { $0 += 1 }
                return eligible
            }

            let first = await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check)
            let second = await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check)

            expect(first) == eligible
            expect(second) == eligible
            expect(invocations.value) == 1
        }
        self.logger.verifyMessageWasLogged("reusing cached result for subscription group 'group'", expectedCount: 2)
        self.logger.verifyMessageWasLogged("starting StoreKit check", expectedCount: 2)
    }

    func testConcurrentChecksShareWorkEvenWhenFirstCallerIsCancelled() async throws {
        let cache = IntroEligibilityGroupCache()
        let check = HeldSubscriptionGroupEligibilityCheck()
        defer { check.completeAll() }
        let first = Task { await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait { check.invocations == ["group"] }

        let second = Task { await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait {
            self.logger.messages.contains { $0.message.contains("reusing in-flight check") }
        }
        first.cancel()
        check.complete(at: 0, eligible: true)

        let firstResult = await first.value
        let secondResult = await second.value
        let cachedResult = await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check.call)

        expect(firstResult) == true
        expect(secondResult) == true
        expect(cachedResult) == true
        expect(check.invocations) == ["group"]
        expect(check.wasCancelled.value) == false
        self.logger.verifyMessageWasLogged("starting StoreKit check", expectedCount: 1)
        self.logger.verifyMessageWasLogged("reusing in-flight check", expectedCount: 1)
    }

    func testInvalidationClearsCompletedResultsWhilePreservingPendingChecks() async throws {
        let cache = IntroEligibilityGroupCache()
        let check = HeldSubscriptionGroupEligibilityCheck()
        defer { check.completeAll() }
        let first = Task { await cache.eligibility(for: "pending", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait { check.invocations == ["pending"] }

        let completed = await cache.eligibility(for: "completed", log: IntroEligibilityLog(), check: { _ in true })
        expect(completed) == true
        cache.clearCache()
        cache.clearCache()

        let second = Task { await cache.eligibility(for: "pending", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait {
            self.logger.messages.contains { $0.message.contains("reusing in-flight check") }
        }
        let refreshed = Task {
            await cache.eligibility(for: "completed", log: IntroEligibilityLog(), check: check.call)
        }
        try await asyncWait { check.invocations == ["pending", "completed"] }
        check.complete(at: 1, eligible: false)
        let refreshedResult = await refreshed.value
        expect(refreshedResult) == false

        check.complete(at: 0, eligible: true)
        let firstResult = await first.value
        let secondResult = await second.value
        let cached = await cache.eligibility(for: "pending", log: IntroEligibilityLog(), check: { _ in
            XCTFail("The check that survived invalidation should have cached its result")
            return false
        })
        expect(firstResult) == true
        expect(secondResult) == true
        expect(cached) == true
        expect(check.invocations) == ["pending", "completed"]
    }

    func testInvalidationAfterSharedCheckCompletesStartsFreshCheck() async throws {
        let cache = IntroEligibilityGroupCache()
        let check = HeldSubscriptionGroupEligibilityCheck()
        defer { check.completeAll() }
        let first = Task { await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait { check.invocations == ["group"] }
        cache.clearCache()
        check.complete(at: 0, eligible: true)
        let firstResult = await first.value
        expect(firstResult) == true

        cache.clearCache()
        let second = Task { await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait { check.invocations == ["group", "group"] }
        check.complete(at: 1, eligible: false)
        let secondResult = await second.value
        let cached = await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: { _ in
            XCTFail("The fresh check should have cached its result")
            return true
        })

        expect(secondResult) == false
        expect(cached) == false
        expect(check.invocations) == ["group", "group"]
    }

    func testUnrelatedGroupStartsAndCompletesWhileFirstGroupIsPending() async throws {
        let cache = IntroEligibilityGroupCache()
        let check = HeldSubscriptionGroupEligibilityCheck()
        defer { check.completeAll() }
        let firstFinished = Atomic(false)
        let first = Task {
            let result = await cache.eligibility(for: "first", log: IntroEligibilityLog(), check: check.call)
            firstFinished.value = true
            return result
        }
        try await asyncWait { check.invocations == ["first"] }

        let second = Task { await cache.eligibility(for: "second", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait { check.invocations == ["first", "second"] }
        check.complete(at: 1, eligible: false)

        let secondResult = await second.value
        expect(secondResult) == false
        expect(firstFinished.value) == false

        check.complete(at: 0, eligible: true)
        let firstResult = await first.value
        expect(firstResult) == true
    }

}
