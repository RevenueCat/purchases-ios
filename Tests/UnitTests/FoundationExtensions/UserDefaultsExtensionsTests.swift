//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UserDefaultsExtensionsTests.swift
//
//  Created by Nacho Soto on 11/9/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class UserDefaultsExtensionsTests: TestCase {

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

private extension UserDefaultsExtensionsTests {

    static let appUserKey: String = DeviceCache.CacheKeys.appUserDefaults.rawValue

}
