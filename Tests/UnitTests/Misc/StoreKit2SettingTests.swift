//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2SettingTests.swift
//
//  Created by Nacho Soto on 9/1/22.

import Nimble
import XCTest

@testable import RevenueCat

class StoreKit2SettingTests: TestCase {

    func testStoreKit2NotAvailableWhenDisabled() {
        expect(StoreKit2Setting.disabled.shouldOnlyUseStoreKit2) == false
    }

    func testShouldOnlyUseStoreKit2FalseWhenOnlyEnabledForOptimizations() {
        expect(StoreKit2Setting.enabledOnlyForOptimizations.shouldOnlyUseStoreKit2) == false
    }

    func testShouldOnlyUseStoreKitFalseIfNotAvailable() throws {
        try AvailabilityChecks.iOS15APINotAvailableOrSkipTest()

        expect(StoreKit2Setting.enabledForCompatibleDevices.shouldOnlyUseStoreKit2) == false
    }

    func testShouldOnlyUseStoreKitTrueIfAvailable() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(StoreKit2Setting.enabledForCompatibleDevices.shouldOnlyUseStoreKit2) == true
    }

    func testStoreKit2NotAvailableOnOlderDevices() throws {
        try AvailabilityChecks.iOS15APINotAvailableOrSkipTest()

        expect(StoreKit2Setting.isStoreKit2Available) == false
    }

    func testStoreKit2AvailableOnNewerDevices() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(StoreKit2Setting.isStoreKit2Available) == true
    }

}
