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

    // MARK: - LocalTransactionMetadata Tests

    func testLocalTransactionMetadataDecodingAndIdempotency() throws {
        let json = """
        {
            "transaction_id": "tx_123456",
            "product_data_wrapper": {
                "product_identifier": "com.test.product",
                "payment_mode_raw_value": 1,
                "currency_code": "USD",
                "store_country": "US",
                "price_string": "9.99",
                "normal_duration": "P1M",
                "intro_duration": "P1W",
                "intro_duration_type_raw_value": 2,
                "intro_price_string": "0",
                "subscription_group": "group_123",
                "discounts": null
            },
            "purchased_transaction_data_wrapper": {
                "presented_paywall": null,
                "unsynced_attributes": null,
                "metadata": {"key": "value"},
                "aad_attribution_token": "test_attribution_token",
                "store_country": "US",
                "offering_identifier": "offering_123",
                "placement_identifier": "placement_456",
                "targeting_context_revision": 1,
                "targeting_context_rule_id": "rule_789"
            },
            "encoded_apple_receipt": {
                "jws": {
                    "_0": "test_jws_token"
                }
            },
            "original_purchases_are_completed_by": 0,
            "sdk_originated": true
        }
        """

        // Decode from snake_case JSON
        let decoded = try JSONDecoder.default.decode(
            LocalTransactionMetadata.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded values
        expect(decoded.transactionId) == "tx_123456"
        expect(decoded.sdkOriginated) == true
        expect(decoded.originalPurchasesAreCompletedBy) == .revenueCat

        // Verify product data
        let decodedProductData = try XCTUnwrap(decoded.productData)
        expect(decodedProductData.productIdentifier) == "com.test.product"
        expect(decodedProductData.paymentMode) == .payUpFront
        expect(decodedProductData.currencyCode) == "USD"
        expect(decodedProductData.storeCountry) == "US"
        expect(decodedProductData.price) == Decimal(string: "9.99")!
        expect(decodedProductData.normalDuration) == "P1M"
        expect(decodedProductData.introDuration) == "P1W"
        expect(decodedProductData.introDurationType) == .freeTrial
        expect(decodedProductData.introPrice) == Decimal(string: "0")!
        expect(decodedProductData.subscriptionGroup) == "group_123"

        // Verify transaction data
        expect(decoded.transactionData.presentedOfferingContext?.offeringIdentifier) == "offering_123"
        expect(decoded.transactionData.presentedOfferingContext?.placementIdentifier) == "placement_456"
        expect(decoded.transactionData.presentedOfferingContext?.targetingContext?.revision) == 1
        expect(decoded.transactionData.presentedOfferingContext?.targetingContext?.ruleId) == "rule_789"
        expect(decoded.transactionData.metadata) == ["key": "value"]
        expect(decoded.transactionData.aadAttributionToken) == "test_attribution_token"
        expect(decoded.transactionData.storeCountry) == "US"

        // Verify encoded receipt
        guard case .jws(let jwsString) = decoded.encodedAppleReceipt else {
            fail("Expected .jws case")
            return
        }
        expect(jwsString) == "test_jws_token"

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(LocalTransactionMetadata.self, from: encoded)

        // Verify values after round-trip
        expect(reDecoded.transactionId) == decoded.transactionId
        expect(reDecoded.sdkOriginated) == decoded.sdkOriginated
        expect(reDecoded.originalPurchasesAreCompletedBy) == decoded.originalPurchasesAreCompletedBy
        expect(reDecoded.productData?.productIdentifier) == decoded.productData?.productIdentifier
        expect(reDecoded.transactionData.presentedOfferingContext?.offeringIdentifier)
            == decoded.transactionData.presentedOfferingContext?.offeringIdentifier
    }

    func testLocalTransactionMetadataWithNilProductDataDecodingAndIdempotency() throws {
        let json = """
        {
            "transaction_id": "tx_minimal",
            "product_data_wrapper": null,
            "purchased_transaction_data_wrapper": {
                "presented_paywall": null,
                "unsynced_attributes": null,
                "metadata": null,
                "aad_attribution_token": null,
                "store_country": null,
                "offering_identifier": null,
                "placement_identifier": null,
                "targeting_context_revision": null,
                "targeting_context_rule_id": null
            },
            "encoded_apple_receipt": {
                "empty": {}
            },
            "original_purchases_are_completed_by": 1,
            "sdk_originated": false
        }
        """

        // Decode from snake_case JSON
        let decoded = try JSONDecoder.default.decode(
            LocalTransactionMetadata.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded values
        expect(decoded.transactionId) == "tx_minimal"
        expect(decoded.sdkOriginated) == false
        expect(decoded.originalPurchasesAreCompletedBy) == .myApp
        expect(decoded.productData).to(beNil())
        expect(decoded.transactionData.presentedOfferingContext).to(beNil())
        expect(decoded.transactionData.metadata).to(beNil())

        // Verify encoded receipt
        guard case .empty = decoded.encodedAppleReceipt else {
            fail("Expected .empty case")
            return
        }

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(LocalTransactionMetadata.self, from: encoded)

        // Verify values after round-trip
        expect(reDecoded.transactionId) == decoded.transactionId
        expect(reDecoded.sdkOriginated) == decoded.sdkOriginated
        expect(reDecoded.originalPurchasesAreCompletedBy) == decoded.originalPurchasesAreCompletedBy
        expect(reDecoded.productData).to(beNil())
    }

    func testLocalTransactionMetadataWithSK2ReceiptDecodingAndIdempotency() throws {
        let json = """
        {
            "transaction_id": "tx_sk2_receipt",
            "product_data_wrapper": null,
            "purchased_transaction_data_wrapper": {
                "presented_paywall": null,
                "unsynced_attributes": null,
                "metadata": null,
                "aad_attribution_token": null,
                "store_country": "DE",
                "offering_identifier": "default",
                "placement_identifier": null,
                "targeting_context_revision": null,
                "targeting_context_rule_id": null
            },
            "encoded_apple_receipt": {
                "sk2receipt": {
                    "_0": {
                        "environment": "sandbox",
                        "subscription_status": {},
                        "transactions": ["tx_1", "tx_2"],
                        "bundle_id": "com.test.bundle",
                        "original_application_version": "1.0.0",
                        "original_purchase_date": "2021-01-01T00:00:00Z"
                    }
                }
            },
            "original_purchases_are_completed_by": 0,
            "sdk_originated": true
        }
        """

        // Decode from snake_case JSON
        let decoded = try JSONDecoder.default.decode(
            LocalTransactionMetadata.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded values
        expect(decoded.transactionId) == "tx_sk2_receipt"
        expect(decoded.sdkOriginated) == true
        expect(decoded.transactionData.storeCountry) == "DE"
        expect(decoded.transactionData.presentedOfferingContext?.offeringIdentifier) == "default"

        // Verify encoded receipt
        guard case .sk2receipt(let receipt) = decoded.encodedAppleReceipt else {
            fail("Expected .sk2receipt case")
            return
        }
        expect(receipt.environment) == .sandbox
        expect(receipt.bundleId) == "com.test.bundle"
        expect(receipt.originalApplicationVersion) == "1.0.0"
        expect(receipt.transactions) == ["tx_1", "tx_2"]

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(LocalTransactionMetadata.self, from: encoded)

        // Verify values after round-trip
        expect(reDecoded.transactionId) == decoded.transactionId

        guard case .sk2receipt(let reDecodedReceipt) = reDecoded.encodedAppleReceipt else {
            fail("Expected .sk2receipt case after round-trip")
            return
        }
        expect(reDecodedReceipt.environment) == receipt.environment
        expect(reDecodedReceipt.bundleId) == receipt.bundleId
    }

    func testLocalTransactionMetadataWithProductDiscountsDecodingAndIdempotency() throws {
        let json = """
        {
            "transaction_id": "tx_with_discounts",
            "product_data_wrapper": {
                "product_identifier": "com.test.premium",
                "payment_mode_raw_value": 0,
                "currency_code": "EUR",
                "store_country": "DE",
                "price_string": "19.99",
                "normal_duration": "P1Y",
                "intro_duration": null,
                "intro_duration_type_raw_value": null,
                "intro_price_string": null,
                "subscription_group": "premium_group",
                "discounts": [
                    {
                        "offer_identifier": "discount_offer",
                        "currency_code": "EUR",
                        "price": 1.99,
                        "localized_price_string": "€1.99",
                        "payment_mode": 0,
                        "subscription_period": {
                            "value": 1,
                            "unit": 1
                        },
                        "number_of_periods": 4,
                        "type": 1
                    }
                ]
            },
            "purchased_transaction_data_wrapper": {
                "presented_paywall": null,
                "unsynced_attributes": null,
                "metadata": null,
                "aad_attribution_token": null,
                "store_country": null,
                "offering_identifier": null,
                "placement_identifier": null,
                "targeting_context_revision": null,
                "targeting_context_rule_id": null
            },
            "encoded_apple_receipt": {
                "jws": {
                    "_0": "discount_jws_token"
                }
            },
            "original_purchases_are_completed_by": 0,
            "sdk_originated": true
        }
        """

        // Decode from snake_case JSON
        let decoded = try JSONDecoder.default.decode(
            LocalTransactionMetadata.self,
            from: json.data(using: .utf8)!
        )

        // Verify decoded values
        expect(decoded.transactionId) == "tx_with_discounts"

        let decodedProductData = try XCTUnwrap(decoded.productData)
        expect(decodedProductData.productIdentifier) == "com.test.premium"
        expect(decodedProductData.currencyCode) == "EUR"
        expect(decodedProductData.price) == Decimal(string: "19.99")!
        expect(decodedProductData.normalDuration) == "P1Y"
        expect(decodedProductData.introDuration).to(beNil())
        expect(decodedProductData.introPrice).to(beNil())

        // Verify discounts
        let decodedDiscounts = try XCTUnwrap(decodedProductData.discounts)
        expect(decodedDiscounts.count) == 1
        expect(decodedDiscounts[0].offerIdentifier) == "discount_offer"
        expect(decodedDiscounts[0].currencyCode) == "EUR"
        expect(decodedDiscounts[0].price) == Decimal(string: "1.99")!
        expect(decodedDiscounts[0].paymentMode) == .payAsYouGo
        expect(decodedDiscounts[0].subscriptionPeriod.value) == 1
        expect(decodedDiscounts[0].subscriptionPeriod.unit) == .week
        expect(decodedDiscounts[0].numberOfPeriods) == 4
        expect(decodedDiscounts[0].type) == .promotional

        // Encode and decode again to verify idempotency
        let encoded = try JSONEncoder.default.encode(decoded)
        let reDecoded = try JSONDecoder.default.decode(LocalTransactionMetadata.self, from: encoded)

        // Verify values after round-trip
        expect(reDecoded.transactionId) == decoded.transactionId
        expect(reDecoded.productData?.discounts?.count) == 1
        expect(reDecoded.productData?.discounts?[0].offerIdentifier) == "discount_offer"
    }

}
