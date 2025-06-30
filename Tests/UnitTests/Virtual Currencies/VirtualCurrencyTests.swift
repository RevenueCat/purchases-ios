//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrencyTests.swift
//
//  Created by Will Taylor on 6/10/25.

import Foundation
@testable import RevenueCat
import XCTest

final class VirtualCurrencyTests: TestCase {

    func testInitializer() {
        let currency = VirtualCurrency(
            balance: 100,
            name: "Test Currency",
            code: "TEST",
            serverDescription: "Test Description"
        )

        XCTAssertEqual(currency.balance, 100)
        XCTAssertEqual(currency.name, "Test Currency")
        XCTAssertEqual(currency.code, "TEST")
        XCTAssertEqual(currency.serverDescription, "Test Description")
    }

    func testInitializerWithNilDescription() {
        let currency = VirtualCurrency(
            balance: 100,
            name: "Test Currency",
            code: "TEST",
            serverDescription: nil
        )

        XCTAssertEqual(currency.balance, 100)
        XCTAssertEqual(currency.name, "Test Currency")
        XCTAssertEqual(currency.code, "TEST")
        XCTAssertNil(currency.serverDescription)
    }

    func testEquality() {
        let currency1 = VirtualCurrency(
            balance: 100,
            name: "Test Currency",
            code: "TEST",
            serverDescription: "Test Description"
        )
        let currency2 = VirtualCurrency(
            balance: 100,
            name: "Different Name",
            code: "DIFF",
            serverDescription: "Different Description"
        )
        let currency3 = VirtualCurrency(
            balance: 200,
            name: "Test Currency",
            code: "TEST",
            serverDescription: "Test Description"
        )

        XCTAssertFalse(currency1.isEqual(currency2))
        XCTAssertFalse(currency1.isEqual(currency3))
        XCTAssertFalse(currency1.isEqual(nil))
        XCTAssertFalse(currency1.isEqual("Not a currency"))

        XCTAssertTrue(currency1.isEqual(currency1))
        XCTAssertTrue(currency2.isEqual(currency2))
        XCTAssertTrue(currency3.isEqual(currency3))
    }

    func testInitializerFromResponse() {
        let response = VirtualCurrenciesResponse.VirtualCurrencyResponse(
            balance: 100,
            name: "Test Currency",
            code: "TEST",
            description: "Test Description"
        )

        let currency = VirtualCurrency(from: response)

        XCTAssertEqual(currency.balance, 100)
        XCTAssertEqual(currency.name, "Test Currency")
        XCTAssertEqual(currency.code, "TEST")
        XCTAssertEqual(currency.serverDescription, "Test Description")
    }

    func testInitializerFromResponseWithNilDescription() {
        let response = VirtualCurrenciesResponse.VirtualCurrencyResponse(
            balance: 100,
            name: "Test Currency",
            code: "TEST",
            description: nil
        )

        let currency = VirtualCurrency(from: response)

        XCTAssertEqual(currency.balance, 100)
        XCTAssertEqual(currency.name, "Test Currency")
        XCTAssertEqual(currency.code, "TEST")
        XCTAssertNil(currency.serverDescription)
    }

}
