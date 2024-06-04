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

    func testInitWithTrue() {
        expect(StoreKit2Setting(useStoreKit2IfAvailable: true)) == .enabledForCompatibleDevices
        expect(StoreKit2Setting(useStoreKit2IfAvailable: true).usesStoreKit2IfAvailable) == true
    }

    func testInitWithFalse() {
        expect(StoreKit2Setting(useStoreKit2IfAvailable: false)) == .enabledOnlyForOptimizations
        expect(StoreKit2Setting(useStoreKit2IfAvailable: false).usesStoreKit2IfAvailable) == false
    }

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

    func testIsEnabledAndAvailableFalseWhenOnlyEnabledForOptimizations() {
        expect(StoreKit2Setting.enabledOnlyForOptimizations.isEnabledAndAvailable) == false
    }

    func testIsEnabledAndAvailableFalseIfNotAvailable() throws {
        try AvailabilityChecks.iOS15APINotAvailableOrSkipTest()

        expect(StoreKit2Setting.enabledForCompatibleDevices.isEnabledAndAvailable) == false
    }

    func testIsEnabledAndAvailableTrueIfAvailable() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(StoreKit2Setting.enabledForCompatibleDevices.isEnabledAndAvailable) == true
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
