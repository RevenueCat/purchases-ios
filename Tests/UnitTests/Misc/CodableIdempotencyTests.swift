//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CodableIdempotencyTests.swift
//
//  Tests to verify that Codable types decode correctly from snake_case JSON
//  and that encoding → decoding is idempotent when using JSONEncoder.default
//  and JSONDecoder.default (which use convertToSnakeCase and convertFromSnakeCase).

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

/// These tests verify that Codable types:
/// 1. Decode correctly from JSON with snake_case keys (as the backend sends + the default encoder/decoder expect)
/// 2. Remain idempotent after encode → decode cycle using default encoder/decoder
///
/// For Encodable-only types, we verify that encoding produces the expected snake_case keys.
///
/// This ensures CodingKeys are properly configured for snake_case key conversion strategies.
class CodableIdempotencyTests: TestCase {

    // MARK: - StoreKit2Receipt Tests

    func testStoreKit2ReceiptDecodingAndIdempotency() throws {
        let json = """
        {
            "environment": "sandbox",
            "subscription_status": {
                "group_123": [
                    {
                        "state": 1,
                        "renewal_info": "renewal_jws_token_value",
                        "transaction": "transaction_jws_token_value"
                    }
                ]
            },
            "transactions": ["tx_1", "tx_2"],
            "bundle_id": "com.test.app",
            "original_application_version": "1.0.0",
            "original_purchase_date": "2022-04-12T00:03:24Z"
        }
        """

        // Decode from snake_case JSON
        let decoded = try JSONDecoder.default.decode(
            StoreKit2Receipt.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded values
        let expectedDate = ISO8601DateFormatter().date(from: "2022-04-12T00:03:24Z")
        expect(decoded.environment) == .sandbox
        expect(decoded.bundleId) == "com.test.app"
        expect(decoded.originalApplicationVersion) == "1.0.0"
        expect(decoded.originalPurchaseDate) == expectedDate
        expect(decoded.transactions) == ["tx_1", "tx_2"]

        let statuses = try XCTUnwrap(decoded.subscriptionStatusBySubscriptionGroupId["group_123"])
        expect(statuses.count) == 1
        expect(statuses[0].state) == .subscribed
        expect(statuses[0].renewalInfoJWSToken) == "renewal_jws_token_value"
        expect(statuses[0].transactionJWSToken) == "transaction_jws_token_value"

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(StoreKit2Receipt.self, from: encoded)

        // Verify values after round-trip
        expect(reDecoded.environment) == .sandbox
        expect(reDecoded.bundleId) == "com.test.app"
        expect(reDecoded.originalApplicationVersion) == "1.0.0"
        expect(reDecoded.originalPurchaseDate) == expectedDate
        expect(reDecoded.transactions) == ["tx_1", "tx_2"]

        let reDecodedStatuses = try XCTUnwrap(reDecoded.subscriptionStatusBySubscriptionGroupId["group_123"])
        expect(reDecodedStatuses.count) == 1
        expect(reDecodedStatuses[0].state) == .subscribed
        expect(reDecodedStatuses[0].renewalInfoJWSToken) == "renewal_jws_token_value"
        expect(reDecodedStatuses[0].transactionJWSToken) == "transaction_jws_token_value"

        // Verify full equality
        expect(reDecoded) == decoded
    }

    // MARK: - StoreKit2Receipt.SubscriptionStatus Tests

    func testStoreKit2ReceiptSubscriptionStatusDecodingAndIdempotency() throws {
        let json = """
        {
            "state": 3,
            "renewal_info": "test_renewal_info_jws",
            "transaction": "test_transaction_jws"
        }
        """

        // Decode from snake_case JSON
        let decoded = try JSONDecoder.default.decode(
            StoreKit2Receipt.SubscriptionStatus.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded values
        expect(decoded.state) == .inBillingRetryPeriod
        expect(decoded.renewalInfoJWSToken) == "test_renewal_info_jws"
        expect(decoded.transactionJWSToken) == "test_transaction_jws"

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(
            StoreKit2Receipt.SubscriptionStatus.self,
            from: encoded
        )

        // Verify values after round-trip
        expect(reDecoded.state) == .inBillingRetryPeriod
        expect(reDecoded.renewalInfoJWSToken) == "test_renewal_info_jws"
        expect(reDecoded.transactionJWSToken) == "test_transaction_jws"

        // Verify full equality
        expect(reDecoded) == decoded
    }

    // MARK: - CustomerCenterConfigResponse.Support.SupportTickets.CustomerDetails Tests

    func testCustomerDetailsDecodingAndIdempotency() throws {
        let json = """
        {
            "active_entitlements": true,
            "app_user_id": true,
            "att_consent": false,
            "country": true,
            "device_version": true,
            "email": true,
            "facebook_anon_id": false,
            "idfa": true,
            "idfv": true,
            "ip": false,
            "last_opened": true,
            "last_seen_app_version": true,
            "total_spent": true,
            "user_since": true
        }
        """

        // Decode from snake_case JSON
        let decoded = try JSONDecoder.default.decode(
            CustomerCenterConfigResponse.Support.SupportTickets.CustomerDetails.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded values
        expect(decoded.activeEntitlements) == true
        expect(decoded.appUserId) == true
        expect(decoded.attConsent) == false
        expect(decoded.country) == true
        expect(decoded.deviceVersion) == true
        expect(decoded.email) == true
        expect(decoded.facebookAnonId) == false
        expect(decoded.idfa) == true
        expect(decoded.idfv) == true
        expect(decoded.ipAddress) == false
        expect(decoded.lastOpened) == true
        expect(decoded.lastSeenAppVersion) == true
        expect(decoded.totalSpent) == true
        expect(decoded.userSince) == true

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(
            CustomerCenterConfigResponse.Support.SupportTickets.CustomerDetails.self,
            from: encoded
        )

        // Verify values after round-trip
        expect(reDecoded.activeEntitlements) == true
        expect(reDecoded.appUserId) == true
        expect(reDecoded.attConsent) == false
        expect(reDecoded.country) == true
        expect(reDecoded.deviceVersion) == true
        expect(reDecoded.email) == true
        expect(reDecoded.facebookAnonId) == false
        expect(reDecoded.idfa) == true
        expect(reDecoded.idfv) == true
        expect(reDecoded.ipAddress) == false
        expect(reDecoded.lastOpened) == true
        expect(reDecoded.lastSeenAppVersion) == true
        expect(reDecoded.totalSpent) == true
        expect(reDecoded.userSince) == true

        // Verify full equality
        expect(reDecoded) == decoded
    }

    // MARK: - ProductRequestData Tests (Encodable only)

    func testProductRequestDataEncodesToExpectedSnakeCaseKeys() throws {
        let productData = ProductRequestData(
            productIdentifier: "com.test.product",
            paymentMode: .payUpFront,
            currencyCode: "USD",
            storeCountry: "US",
            price: Decimal(string: "9.99")!,
            normalDuration: "P1M",
            introDuration: "P1W",
            introDurationType: .payUpFront,
            introPrice: Decimal(string: "4.99")!,
            subscriptionGroup: "group_123",
            discounts: nil
        )

        let encoded = try JSONEncoder.default.encode(productData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        // Verify snake_case keys and values
        expect(json["product_id"] as? String) == "com.test.product"
        expect(json["payment_mode"] as? Int) == StoreProductDiscount.PaymentMode.payUpFront.rawValue
        expect(json["currency"] as? String) == "USD"
        expect(json["store_country"] as? String) == "US"
        expect(json["price"] as? String) == "9.99"
        expect(json["normal_duration"] as? String) == "P1M"
        expect(json["intro_duration"] as? String) == "P1W"
        expect(json["introductory_price"] as? String) == "4.99"
        expect(json["subscription_group_id"] as? String) == "group_123"
    }

    func testProductRequestDataEncodesTrialDurationCorrectly() throws {
        let productData = ProductRequestData(
            productIdentifier: "com.test.product",
            paymentMode: nil,
            currencyCode: "EUR",
            storeCountry: "DE",
            price: Decimal(string: "19.99")!,
            normalDuration: "P1Y",
            introDuration: "P2W",
            introDurationType: .freeTrial,
            introPrice: Decimal.zero,
            subscriptionGroup: nil,
            discounts: nil
        )

        let encoded = try JSONEncoder.default.encode(productData)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        // For freeTrial, introDuration should be encoded as trial_duration
        expect(json["trial_duration"] as? String) == "P2W"
        expect(json["intro_duration"]).to(beNil())
    }

    // MARK: - StoreProductDiscount Tests (Encodable only)

    func testStoreProductDiscountEncodesToExpectedSnakeCaseKeys() throws {
        let discount = MockStoreProductDiscount(
            offerIdentifier: "test_offer_id",
            currencyCode: "USD",
            price: Decimal(string: "2.99")!,
            localizedPriceString: "$2.99",
            paymentMode: .payAsYouGo,
            subscriptionPeriod: .init(value: 1, unit: .month),
            numberOfPeriods: 3,
            type: .promotional
        )

        let storeDiscount = StoreProductDiscount.from(discount: discount)

        let encoded = try JSONEncoder.default.encode(storeDiscount)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        // Verify snake_case keys and values
        expect(json["offer_identifier"] as? String) == "test_offer_id"
        expect(json["price"] as? String) == "2.99"
        expect(json["payment_mode"] as? Int) == StoreProductDiscount.PaymentMode.payAsYouGo.rawValue
    }

    func testStoreProductDiscountEncodesNilOfferIdentifier() throws {
        let discount = MockStoreProductDiscount(
            offerIdentifier: nil,
            currencyCode: "EUR",
            price: Decimal.zero,
            localizedPriceString: "Free",
            paymentMode: .freeTrial,
            subscriptionPeriod: .init(value: 7, unit: .day),
            numberOfPeriods: 1,
            type: .introductory
        )

        let storeDiscount = StoreProductDiscount.from(discount: discount)

        let encoded = try JSONEncoder.default.encode(storeDiscount)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        // Verify nil value is encoded as null
        expect(json["offer_identifier"] is NSNull) == true
        expect(json["price"] as? String) == "0"
        expect(json["payment_mode"] as? Int) == StoreProductDiscount.PaymentMode.freeTrial.rawValue
    }

    // MARK: - EncodedAppleReceipt Tests

    func testEncodedAppleReceiptJWSDecodingAndIdempotency() throws {
        // Swift's default Codable uses the case name as key and "_0" for the associated value
        let json = """
        {
            "jws": {
                "_0": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.test_payload.signature"
            }
        }
        """

        // Decode from JSON
        let decoded = try JSONDecoder.default.decode(
            EncodedAppleReceipt.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded value
        guard case .jws(let jwsString) = decoded else {
            fail("Expected .jws case")
            return
        }
        expect(jwsString) == "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.test_payload.signature"

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(EncodedAppleReceipt.self, from: encoded)

        // Verify values after round-trip
        guard case .jws(let reDecodedJwsString) = reDecoded else {
            fail("Expected .jws case after round-trip")
            return
        }
        expect(reDecodedJwsString) == "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.test_payload.signature"

        // Verify full equality
        expect(reDecoded) == decoded
    }

    func testEncodedAppleReceiptReceiptDataDecodingAndIdempotency() throws {
        let base64Data = "SGVsbG8gV29ybGQh" // "Hello World!" in base64
        let json = """
        {
            "receipt": {
                "_0": "\(base64Data)"
            }
        }
        """

        // Decode from JSON
        let decoded = try JSONDecoder.default.decode(
            EncodedAppleReceipt.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded value
        guard case .receipt(let data) = decoded else {
            fail("Expected .receipt case")
            return
        }
        expect(String(data: data, encoding: .utf8)) == "Hello World!"

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(EncodedAppleReceipt.self, from: encoded)

        // Verify values after round-trip
        guard case .receipt(let reDecodedData) = reDecoded else {
            fail("Expected .receipt case after round-trip")
            return
        }
        expect(String(data: reDecodedData, encoding: .utf8)) == "Hello World!"

        // Verify full equality
        expect(reDecoded) == decoded
    }

    func testEncodedAppleReceiptSK2ReceiptDecodingAndIdempotency() throws {
        let json = """
        {
            "sk2receipt": {
                "_0": {
                    "environment": "production",
                    "subscription_status": {},
                    "transactions": ["tx_123"],
                    "bundle_id": "com.test.app",
                    "original_application_version": "1.0.0",
                    "original_purchase_date": "2023-06-15T10:30:00Z"
                }
            }
        }
        """

        // Decode from JSON
        let decoded = try JSONDecoder.default.decode(
            EncodedAppleReceipt.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded value
        guard case .sk2receipt(let receipt) = decoded else {
            fail("Expected .sk2receipt case")
            return
        }
        expect(receipt.environment) == .production
        expect(receipt.bundleId) == "com.test.app"
        expect(receipt.originalApplicationVersion) == "1.0.0"
        expect(receipt.transactions) == ["tx_123"]

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(EncodedAppleReceipt.self, from: encoded)

        // Verify values after round-trip
        guard case .sk2receipt(let reDecodedReceipt) = reDecoded else {
            fail("Expected .sk2receipt case after round-trip")
            return
        }
        expect(reDecodedReceipt.environment) == .production
        expect(reDecodedReceipt.bundleId) == "com.test.app"
        expect(reDecodedReceipt.originalApplicationVersion) == "1.0.0"
        expect(reDecodedReceipt.transactions) == ["tx_123"]

        // Verify full equality
        expect(reDecoded) == decoded
    }

    func testEncodedAppleReceiptEmptyDecodingAndIdempotency() throws {
        let json = """
        {
            "empty": {}
        }
        """

        // Decode from JSON
        let decoded = try JSONDecoder.default.decode(
            EncodedAppleReceipt.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded value
        guard case .empty = decoded else {
            fail("Expected .empty case")
            return
        }

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(EncodedAppleReceipt.self, from: encoded)

        // Verify values after round-trip
        guard case .empty = reDecoded else {
            fail("Expected .empty case after round-trip")
            return
        }

        // Verify full equality
        expect(reDecoded) == decoded
    }

}
