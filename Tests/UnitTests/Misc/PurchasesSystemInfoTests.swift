//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesSystemInfoTests.swift
//
//  Created by Antonio Rico Diez on 1/4/25.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesSystemInfoTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testApplicationWillEnterForegroundSetsIsAppBackgroundedStateToFalse() async throws {
        expect(self.systemInfo.isAppBackgroundedState) == false
        self.systemInfo.isAppBackgroundedState = true
        expect(self.systemInfo.isAppBackgroundedState) == true

        self.notificationCenter.fireApplicationWillEnterForegroundNotification()

        expect(self.systemInfo.isAppBackgroundedState) == false
    }

    func testApplicationWillEnterBackgroundSetsIsAppBackgroundedStateToTrue() async throws {
        expect(self.systemInfo.isAppBackgroundedState) == false

        self.notificationCenter.fireApplicationDidEnterBackgroundNotification()

        expect(self.systemInfo.isAppBackgroundedState) == true
    }
}
