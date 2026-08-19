//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformInfoTests.swift
//
//  Created by Antonio Pallares on 17/5/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class PlatformInfoTests: TestCase {

    // MARK: - Equality

    func testSameFieldsAreEqualAndHaveSameHash() {
        let lhs = Purchases.PlatformInfo(flavor: "flutter", version: "1.2.3")
        let rhs = Purchases.PlatformInfo(flavor: "flutter", version: "1.2.3")

        expect(lhs) == rhs
        expect(lhs.hashValue) == rhs.hashValue
    }

    func testDifferentFlavorIsNotEqual() {
        let lhs = Purchases.PlatformInfo(flavor: "flutter", version: "1.2.3")
        let rhs = Purchases.PlatformInfo(flavor: "react-native", version: "1.2.3")

        expect(lhs) != rhs
    }

    func testDifferentVersionIsNotEqual() {
        let lhs = Purchases.PlatformInfo(flavor: "flutter", version: "1.2.3")
        let rhs = Purchases.PlatformInfo(flavor: "flutter", version: "1.2.4")

        expect(lhs) != rhs
    }

    func testIsNotEqualToOtherTypes() {
        let info = Purchases.PlatformInfo(flavor: "flutter", version: "1.2.3")
        expect(info.isEqual("flutter")) == false
    }

}
