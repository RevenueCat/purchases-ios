//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VirtualCurrenciesDecodingTests.swift
//
//  Created by Will Taylor on 6/10/25.

import Nimble
@testable import RevenueCat
import XCTest

class VirtualCurrenciesDecodingTests: BaseHTTPResponseTest {

    func testResponseDataIsCorrectWith2VCs() throws {
        let response: VirtualCurrenciesResponse = try Self.decodeFixture("VirtualCurrencies")

        let virtualCurrencies = try XCTUnwrap(response).virtualCurrencies
        expect(virtualCurrencies.count).to(equal(2))

        let coinVC = try XCTUnwrap(virtualCurrencies["COIN"])
        expect(coinVC.balance).to(equal(1))
        expect(coinVC.code).to(equal("COIN"))
        expect(coinVC.description).to(equal("It's a coin"))
        expect(coinVC.name).to(equal("Coin"))

        let rcCoinVC = try XCTUnwrap(virtualCurrencies["RC_COIN"])
        expect(rcCoinVC.balance).to(equal(0))
        expect(rcCoinVC.code).to(equal("RC_COIN"))
        expect(rcCoinVC.description).to(beNil())
        expect(rcCoinVC.name).to(equal("RC Coin"))
    }

    func testResponseDataIsCorrectWith0VCs() throws {
        let response: VirtualCurrenciesResponse = try Self.decodeFixture("VirtualCurrenciesEmpty")

        let virtualCurrencies = try XCTUnwrap(response).virtualCurrencies
        expect(virtualCurrencies.isEmpty).to(beTrue())
    }
}
