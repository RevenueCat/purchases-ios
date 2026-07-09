//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesDiagnosticsTrackingTests.swift
//
//  Created by Antonio Pallares on 17/3/25.

import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
class PurchasesDiagnosticsTrackingTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupPurchases()
    }

    // `presentCodeRedemptionSheet()` is unavailable on Mac Catalyst (it's `@available(macCatalyst,
    // unavailable)` and its wrapper isn't compiled there), so this test can't run on Catalyst even
    // though `os(iOS)` is true for it.
    #if (os(iOS) && !targetEnvironment(macCatalyst)) || os(visionOS)
    @available(iOS 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    @available(macCatalyst, unavailable)
    func testPresentCodeRedepmtionSheetTracksDiagnostics() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.purchases.presentCodeRedemptionSheet()

        expect(try self.mockDiagnosticsTracker.trackedApplePresentCodeRedemptionSheetRequestCalls.value) == 1
    }
    #endif
}
