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
@testable import RevenueCat
import XCTest

final class VirtualCurrenciesTests: TestCase {

    private static let mockVirtualCurrencyDictionary = [
        "GLD": VirtualCurrency(balance: 100),
        "SLV": VirtualCurrency(balance: 0),
        "COIN": VirtualCurrency(balance: 500)
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

    // MARK: - virtualCurrenciesWithNonZeroBalance Tests
    func testVirtualCurrenciesWithNonZeroBalance() throws {
        let vcInfos = VirtualCurrencies(virtualCurrencies: Self.mockVirtualCurrencyDictionary)

        XCTAssertTrue(vcInfos.all.contains(where: { $0.key == "GLD" }))
        XCTAssertTrue(vcInfos.all.contains(where: { $0.key == "SLV" }))
        XCTAssertTrue(vcInfos.all.contains(where: { $0.key == "COIN" }))

        let nonZeroBalanceVCs = vcInfos.virtualCurrenciesWithNonZeroBalance

        XCTAssertTrue(nonZeroBalanceVCs.contains(where: { $0.key == "GLD" }))
        XCTAssertTrue(nonZeroBalanceVCs.contains(where: { $0.key == "COIN" }))
        let gold = try XCTUnwrap(vcInfos["GLD"], "VirtualCurrencies is missing GLD")
        let coin = try XCTUnwrap(vcInfos["COIN"], "VirtualCurrencies is missing COIN")
        XCTAssertEqual(gold.balance, Self.mockVirtualCurrencyDictionary["GLD"]!.balance)
        XCTAssertEqual(coin.balance, Self.mockVirtualCurrencyDictionary["COIN"]!.balance)

        XCTAssertFalse(nonZeroBalanceVCs.contains(where: { $0.key == "SLV" }))
        let silver = nonZeroBalanceVCs["SLV"]
        XCTAssertNil(silver)
    }

    func testVirtualCurrenciesWithNonZeroBalanceWithAllZeroBalances() throws {
        let zeroBalances = [
            "GLD": VirtualCurrency(balance: 0),
            "SLV": VirtualCurrency(balance: 0),
            "COIN": VirtualCurrency(balance: 0)
        ]
        let vcInfos = VirtualCurrencies(virtualCurrencies: zeroBalances)

        XCTAssertTrue(vcInfos.virtualCurrenciesWithNonZeroBalance.isEmpty)
    }

    func testVirtualCurrenciesWithNonZeroBalanceWithEmptyDictionary() throws {
        let vcInfos = VirtualCurrencies(virtualCurrencies: [:])

        XCTAssertTrue(vcInfos.virtualCurrenciesWithNonZeroBalance.isEmpty)
    }

    // Negative balances aren't supported at the product level, but it's still
    // a good thing to test here anyways
    func testVirtualCurrenciesWithNonZeroBalanceWithNegativeBalances() throws {
        let negativeBalances = [
            "GLD": VirtualCurrency(balance: -100),
            "SLV": VirtualCurrency(balance: -50),
            "COIN": VirtualCurrency(balance: 0)
        ]
        let vcInfos = VirtualCurrencies(virtualCurrencies: negativeBalances)

        XCTAssertTrue(vcInfos.virtualCurrenciesWithNonZeroBalance.isEmpty)
    }

    // MARK: - virtualCurrenciesWithZeroBalance Tests

    func testVirtualCurrenciesWithZeroBalance() throws {
        let vcInfos = VirtualCurrencies(virtualCurrencies: Self.mockVirtualCurrencyDictionary)

        XCTAssertTrue(vcInfos.all.contains(where: { $0.key == "GLD" }))
        XCTAssertTrue(vcInfos.all.contains(where: { $0.key == "SLV" }))
        XCTAssertTrue(vcInfos.all.contains(where: { $0.key == "COIN" }))

        let zeroBalanceVCs = vcInfos.virtualCurrenciesWithZeroBalance

        XCTAssertTrue(zeroBalanceVCs.contains(where: { $0.key == "SLV" }))
        let silver = try XCTUnwrap(zeroBalanceVCs["SLV"], "VirtualCurrencies is missing SLV")
        XCTAssertEqual(silver.balance, Self.mockVirtualCurrencyDictionary["SLV"]!.balance)

        XCTAssertFalse(zeroBalanceVCs.contains(where: { $0.key == "GLD" }))
        XCTAssertFalse(zeroBalanceVCs.contains(where: { $0.key == "COIN" }))
        let gold = zeroBalanceVCs["GLD"]
        let coin = zeroBalanceVCs["COIN"]
        XCTAssertNil(gold)
        XCTAssertNil(coin)
    }

    func testVirtualCurrenciesWithZeroBalanceWithAllNonZeroBalances() throws {
        let nonZeroBalances = [
            "GLD": VirtualCurrency(balance: 100),
            "SLV": VirtualCurrency(balance: 50),
            "COIN": VirtualCurrency(balance: 200)
        ]
        let vcInfos = VirtualCurrencies(virtualCurrencies: nonZeroBalances)

        XCTAssertTrue(vcInfos.virtualCurrenciesWithZeroBalance.isEmpty)
    }

    func testVirtualCurrenciesWithZeroBalanceWithEmptyDictionary() throws {
        let vcInfos = VirtualCurrencies(virtualCurrencies: [:])

        XCTAssertTrue(vcInfos.virtualCurrenciesWithZeroBalance.isEmpty)
    }

    // Negative balances aren't supported at the product level, but it's still
    // a good thing to test here anyways
    func testVirtualCurrenciesWithZeroBalanceWithNegativeBalances() throws {
        let negativeBalances = [
            "GLD": VirtualCurrency(balance: -100),
            "SLV": VirtualCurrency(balance: -50),
            "COIN": VirtualCurrency(balance: 0)
        ]
        let vcInfos = VirtualCurrencies(virtualCurrencies: negativeBalances)

        let zeroBalanceVCs = vcInfos.virtualCurrenciesWithZeroBalance
        XCTAssertTrue(zeroBalanceVCs.contains(where: { $0.key == "COIN" }))
        XCTAssertEqual(zeroBalanceVCs.count, 1)
    }
}
