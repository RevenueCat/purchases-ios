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

class PurchasesGroupEligibilityCacheTests: BasePurchasesTests {

    override var storeKitVersion: StoreKitVersion { .storeKit2 }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.backend.overrideCustomerInfoResult = .success(.emptyInfo)
        self.deviceCache.cachedCustomerInfo[Self.appUserID] = try CustomerInfo.emptyInfo.jsonEncodedData
        self.initializePurchasesInstance(appUserId: Self.appUserID)
    }

    @MainActor
    func testPaywallRequestEscalatesPendingBackgroundCheckThroughProductCache() async throws {
        await expect(self.purchasesDelegate.customerInfo).toEventually(equal(CustomerInfo.emptyInfo))
        let cache = try XCTUnwrap(self.groupEligibilityCache)
        let check = PriorityRecordingGroupCheck()
        defer { check.release() }
        self.trialOrIntroPriceEligibilityChecker.asyncCheckEligibility = { productIDs in
            let eligible = await cache.eligibility(for: "group", log: IntroEligibilityLog(), check: check.call)
            return productIDs.dictionaryWithValues { _ in
                IntroEligibility(eligibilityStatus: eligible ? .eligible : .ineligible)
            }
        }
        let purchases = try XCTUnwrap(self.purchases)
        let warmupFinished = self.expectation(description: "Background callback received result")
        // The completion API and async API must join the same task, including subset requests.
        let warmup = Task.detached(priority: .background) {
            purchases.checkTrialOrIntroDiscountEligibility(productIdentifiers: ["monthly", "annual"]) { result in
                expect(Thread.isMainThread).to(beTrue())
                expect(result.keys).to(haveCount(2))
                warmupFinished.fulfill()
            }
        }
        try await asyncWait { check.initialPriority.value != nil }
        expect(check.initialPriority.value) == .background

        let package = Package(identifier: "monthly", packageType: .monthly,
                              storeProduct: .init(sk1Product: MockSK1Product(mockProductIdentifier: "monthly")),
                              offeringIdentifier: "offering", webCheckoutUrl: nil)
        let paywall = Task.detached(priority: .userInitiated) {
            await purchases.checkTrialOrIntroDiscountEligibility(packages: [package])
        }
        try await asyncWait {
            self.logger.messages.contains { $0.message.contains("Waiting for an in-flight intro eligibility") }
        }
        // Swift 5.9 added propagation through an already-waiting task: https://github.com/swiftlang/swift/pull/63019.
        // Keep verifying sharing and delivery on older runtimes, which only escalate the directly awaited task.
        if #available(iOS 17.0, tvOS 17.0, macOS 14.0, watchOS 10.0, *) {
            // Awaiting either handle here would let the test itself donate priority.
            try await asyncWait { check.currentPriority.value == .userInitiated }
        }
        self.logger.verifyMessageWasLogged("Waiting for an in-flight intro eligibility", expectedCount: 1)
        expect(check.invocations.value) == 1
        check.release()
        let result = await paywall.value
        await warmup.value
        await self.fulfillment(of: [warmupFinished], timeout: 1)
        expect(result) == [package: IntroEligibility(eligibilityStatus: .eligible)]
    }

    @MainActor
    func testCustomerInfoChangeClearsCompletedAndPendingGroupChecks() async throws {
        await expect(self.purchasesDelegate.customerInfo).toEventually(equal(CustomerInfo.emptyInfo))
        let initialClearCount = self.cachingTrialOrIntroPriceEligibilityChecker.invokedClearCacheCount
        let cache = try XCTUnwrap(self.groupEligibilityCache)
        let completed = await cache.eligibility(for: "completed", log: IntroEligibilityLog(), check: { _ in false })
        expect(completed) == false
        let check = HeldSubscriptionGroupEligibilityCheck()
        defer { check.completeAll() }
        let pending = Task { await cache.eligibility(for: "pending", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait { check.invocations == ["pending"] }

        self.customerInfoManager.cache(customerInfo: .missingOriginalApplicationVersion, appUserID: Self.appUserID)
        await expect(self.cachingTrialOrIntroPriceEligibilityChecker.invokedClearCacheCount)
            .toEventually(equal(initialClearCount + 1))

        let refreshed = await cache.eligibility(for: "completed", log: IntroEligibilityLog(), check: { _ in true })
        expect(refreshed) == true
        let fresh = Task { await cache.eligibility(for: "pending", log: IntroEligibilityLog(), check: check.call) }
        try await asyncWait { check.invocations == ["pending", "pending"] }
        check.complete(at: 1, eligible: false)
        let freshResult = await fresh.value
        check.complete(at: 0, eligible: true)
        let pendingResult = await pending.value
        expect(pendingResult) == true
        expect(freshResult) == false
        expect(check.wasCancelled.value) == false
    }

}
