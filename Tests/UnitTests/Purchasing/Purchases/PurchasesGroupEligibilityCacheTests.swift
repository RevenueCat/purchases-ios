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
