//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesTests.swift
//
//  Created by Will Taylor on 5/21/25.

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

final class VirtualCurrenciesTests: TestCase {

    private static let mockVirtualCurrencyDictionary = [
        "GLD": VirtualCurrency(balance: 100, name: "Gold", code: "GLD", serverDescription: "It's gold!"),
        "SLV": VirtualCurrency(balance: 0, name: "Gold", code: "GLD", serverDescription: "It's gold!"),
        "COIN": VirtualCurrency(balance: 500, name: "Gold", code: "GLD", serverDescription: "It's gold!")
    ]

    // MARK: - all Property Tests
    func testAllProperty() throws {
        let vcInfos = VirtualCurrencies(virtualCurrencies: Self.mockVirtualCurrencyDictionary)

        XCTAssertEqual(vcInfos.all, Self.mockVirtualCurrencyDictionary)
    }

    // MARK: - Subscript Tests
    func testSubscriptForVCInVirtualCurrencies() throws {
        let vcInfos = VirtualCurrencies(virtualCurrencies: Self.mockVirtualCurrencyDictionary)

        let gold = try XCTUnwrap(vcInfos["GLD"], "VirtualCurrencies is missing GLD")
        let silver = try XCTUnwrap(vcInfos["SLV"], "VirtualCurrencies is missing SLV")
        let coin = try XCTUnwrap(vcInfos["COIN"], "VirtualCurrencies is missing COIN")

        XCTAssertEqual(gold.balance, Self.mockVirtualCurrencyDictionary["GLD"]!.balance)
        XCTAssertEqual(silver.balance, Self.mockVirtualCurrencyDictionary["SLV"]!.balance)
        XCTAssertEqual(coin.balance, Self.mockVirtualCurrencyDictionary["COIN"]!.balance)
    }

    func testSubscriptReturnsNilForVCNotInVirtualCurrencies() throws {
        let vcInfos = VirtualCurrencies(virtualCurrencies: Self.mockVirtualCurrencyDictionary)

        let missingVC = vcInfos["NON_EXISTENT_VC"]

        XCTAssertNil(missingVC)
    }
}
