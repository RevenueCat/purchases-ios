//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseOwnershipTypeTests.swift
//
//  Created by Nacho Soto on 5/10/22.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class PurchaseOwnershipTypeTests: TestCase {

    func testCodable() throws {
        for type in PurchaseOwnershipType.allCases {
            expect(try type.encodeAndDecode()) == type
        }
    }

    func testUnknownStringBecomesUnknown() throws {
        expect(try PurchaseOwnershipType.decode("\"invalid\"")) == .unknown
    }

    func testNullBecomesUnknown() throws {
        expect(try PurchaseOwnershipType.decode("null")) == .unknown
    }

}
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(PurchaseOwnershipType.from(storeKitOwnershipType: .purchased)) == .purchased
        expect(PurchaseOwnershipType.from(storeKitOwnershipType: .familyShared)) == .familyShared
    }

    #if compiler(>=6.4)
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func testFromStoreKitAssignedOwnershipType() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(PurchaseOwnershipType.from(storeKitOwnershipType: .assigned)) == .assigned
    }
    #endif

}
