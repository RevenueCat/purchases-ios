//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UserDefaultsDefaultTests.swift
//
//  Created by Nacho Soto on 11/9/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

// Note: these are in `StoreKitUnitTests` because they can't run in parallel.
// We run them serially to avoid race conditions while modifying `UserDefaults`.

final class UserDefaultsDefaultTests: TestCase {

    override func setUp() {
        super.setUp()

        UserDefaults.standard.removeObject(forKey: Self.appUserKey)
    }

    func testRevenueCatSuiteIsNotStandard() {
        expect(UserDefaults.revenueCatSuite) !== UserDefaults.standard
    }

    func testDefaultIsStandardIfStandardContainsUserID() {
        UserDefaults.standard.set("user", forKey: Self.appUserKey)

        expect(UserDefaults.computeDefault()) === UserDefaults.standard
    }

    func testDefaultIsRevenueCatSuiteIfStandardDoesNotContainUserID() {
        expect(UserDefaults.computeDefault()) === UserDefaults.revenueCatSuite
    }

    /// Ensures that the logic only checks `UserDefaults.standard`.
    func testDefaultIsRevenueCatSuiteEvenIfItContainsAppUserID() {
        UserDefaults.revenueCatSuite.set("user", forKey: Self.appUserKey)

        expect(UserDefaults.computeDefault()) === UserDefaults.revenueCatSuite
    }

}

private extension UserDefaultsDefaultTests {

    static let appUserKey: String = DeviceCache.CacheKeys.appUserDefaults.rawValue

}
