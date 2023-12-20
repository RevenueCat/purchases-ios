//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitVersionTests.swift
//
//  Created by Mark Villacampa on 4/12/23.

import Nimble
import XCTest

@testable import RevenueCat

class StoreKitVersionTests: TestCase {

    func testVersionStringIsStoreKit1IfStoreKit2EnabledButNotAvailable() throws {
        try AvailabilityChecks.iOS15APINotAvailableOrSkipTest()

        expect(StoreKitVersion.storeKit2.versionString) == "1"
    }

    func testVersionStringIsStoreKit2IfStoreKit2EnabledAndAvailable() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(StoreKitVersion.storeKit2.versionString) == "2"
    }

    func testVersionStringIsStoreKit1IfStoreKit2NotEnabled() {
        expect(StoreKitVersion.storeKit1.versionString) == "1"
    }

    func testStoreKit2EnabledButNotAvailable() throws {
        try AvailabilityChecks.iOS15APINotAvailableOrSkipTest()

        expect(StoreKitVersion.storeKit2.isStoreKit2EnabledAndAvailable) == false
    }

    func testStoreKit2EnabledAndAvailable() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(StoreKitVersion.storeKit2.isStoreKit2EnabledAndAvailable) == true
    }

    func testStoreKit2NotEnabled() {
        expect(StoreKitVersion.storeKit1.isStoreKit2EnabledAndAvailable) == false
    }

    func testStoreKit2NotAvailableOnOlderDevices() throws {
        try AvailabilityChecks.iOS15APINotAvailableOrSkipTest()

        expect(StoreKitVersion.isStoreKit2Available) == false
    }

    func testStoreKit2AvailableOnNewerDevices() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(StoreKitVersion.isStoreKit2Available) == true
    }

}
