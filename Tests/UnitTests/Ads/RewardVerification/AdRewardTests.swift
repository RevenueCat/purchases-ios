//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdRewardTests.swift
//
//  Created by Pol Miro on 27/05/2026.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

final class AdRewardTests: TestCase {

    func testVirtualCurrencyCarriesAssociatedPayload() throws {
        let payload = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let reward = AdReward.virtualCurrency(payload)
        expect(reward.virtualCurrency) == payload
        expect(reward.kindRawValue) == "virtual_currency"
    }

    func testVirtualCurrencyConvenienceFactoryStoresCodeAndAmount() {
        let reward = AdReward.virtualCurrency(code: "coins", amount: 5)
        expect(reward.virtualCurrency?.code) == "coins"
        expect(reward.virtualCurrency?.amount) == 5
    }

    func testNoRewardAndUnsupportedRewardAreDistinct() {
        expect(AdReward.noReward) != .unsupportedReward
        expect(AdReward.noReward) == .noReward
        expect(AdReward.unsupportedReward) == .unsupportedReward
        expect(AdReward.noReward.virtualCurrency).to(beNil())
        expect(AdReward.unsupportedReward.virtualCurrency).to(beNil())
    }

    func testEqualityRequiresMatchingVirtualCurrencyPayload() throws {
        let one = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 5))
        let two = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 6))
        expect(AdReward.virtualCurrency(one)) == AdReward.virtualCurrency(one)
        expect(AdReward.virtualCurrency(one)) != AdReward.virtualCurrency(two)
        expect(AdReward.virtualCurrency(one)) != AdReward.noReward
        expect(AdReward.virtualCurrency(one)) != AdReward.unsupportedReward
    }

    func testKindRawValuesAreStable() {
        expect(AdReward.virtualCurrency(code: "x", amount: 1).kindRawValue) == "virtual_currency"
        expect(AdReward.entitlement(identifier: "pro", expiresAt: Date()).kindRawValue) == "entitlement"
        expect(AdReward.noReward.kindRawValue) == "no_reward"
        expect(AdReward.unsupportedReward.kindRawValue) == "unsupported_reward"
    }

    // MARK: - Entitlement

    func testEntitlementCarriesAssociatedPayload() throws {
        let expiresAt = Date(timeIntervalSince1970: 1_700_000_000)
        let payload = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: expiresAt))
        let reward = AdReward.entitlement(payload)
        expect(reward.entitlement) == payload
        expect(reward.entitlement?.identifier) == "pro"
        expect(reward.entitlement?.expiresAt) == expiresAt
        expect(reward.virtualCurrency).to(beNil())
    }

    func testEntitlementRewardRequiresNonEmptyIdentifier() {
        expect(EntitlementReward(identifier: "", expiresAt: Date())).to(beNil())
    }

    func testEqualityDistinguishesEntitlementFromOtherKinds() throws {
        let expiresAt = Date(timeIntervalSince1970: 1_700_000_000)
        let one = try XCTUnwrap(EntitlementReward(identifier: "pro", expiresAt: expiresAt))
        let differentID = try XCTUnwrap(EntitlementReward(identifier: "plus", expiresAt: expiresAt))
        expect(AdReward.entitlement(one)) == AdReward.entitlement(one)
        expect(AdReward.entitlement(one)) != AdReward.entitlement(differentID)
        expect(AdReward.entitlement(one)) != AdReward.noReward
        expect(AdReward.entitlement(one)) != AdReward.virtualCurrency(code: "coins", amount: 1)
    }

    // MARK: - Flat (analytics events) encoding

    func testEntitlementFlatEncodingEmitsTypeOnlyAndDecodesAsUnsupported() throws {
        let reward = AdReward.entitlement(identifier: "pro", expiresAt: Date())

        let data = try JSONEncoder().encode(FlatRewardWrapper(reward: reward))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        expect(json["type"] as? String) == "entitlement"
        expect(json.keys).toNot(contain("code"))
        expect(json.keys).toNot(contain("amount"))

        let decoded = try JSONDecoder().decode(FlatRewardWrapper.self, from: data)
        expect(decoded.reward) == .unsupportedReward
    }

}

private struct FlatRewardWrapper: Codable, Equatable {

    enum CodingKeys: String, CodingKey {
        case type
        case code
        case amount
    }

    let reward: AdReward

    init(reward: AdReward) {
        self.reward = reward
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try self.reward.encode(into: &container, typeKey: .type, codeKey: .code, amountKey: .amount)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.reward = try AdReward.decode(from: container, typeKey: .type, codeKey: .code, amountKey: .amount)
    }
}
