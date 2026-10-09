//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseTokenIDTests.swift
//
//  Created by Antonio Pallares on 9/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class ExternalPurchaseTokenIDTests: TestCase {

    func testFollowsTheFormatTheBackendMints() {
        expect(ExternalPurchaseTokenID.generate()).to(match("^ept[0-9a-f]{32}$"))
    }

    /// Two registrations must never share an identifier: the backend stores what it is given, and the
    /// checkout ties the purchase back to it.
    func testGeneratesADifferentIdentifierEveryTime() {
        let identifiers = (0..<1000).map { _ in ExternalPurchaseTokenID.generate() }

        expect(Set(identifiers)).to(haveCount(identifiers.count))
    }

}
