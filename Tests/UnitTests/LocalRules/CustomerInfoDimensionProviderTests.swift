//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoDimensionProviderTests.swift
//
//  Created by Rick van der Linden on 8/31/26.
//

import Foundation
import Testing

@testable import RevenueCat

// swiftlint:disable file_length

struct CustomerInfoDimensionProviderTests {

    @Test
    // swiftlint:disable:next function_body_length
    func exposesTheCustomerInfoScope() async throws {
        let provider = Self.provider()

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(provider.name == "customer_info")
        #expect(dimensions == [
            "app_user_id": .string(Self.appUserID),
            "original_app_user_id": .string("original_user"),
            "first_seen_at": .date(Self.date("2022-01-01T00:00:00Z")),
            "original_purchased_at": .date(Self.date("2021-01-01T00:00:00Z")),
            "purchases": .objectList([
                [
                    "kind": .string("subscription"),
                    "product_identifier": .string("premium"),
                    "product_plan_identifier": .string("monthly"),
                    "purchased_product_identifier": .string("premium:monthly"),
                    "store_transaction_id": .string("2000000123456789"),
                    "display_name": .string("Premium Monthly"),
                    "store": .string("app_store"),
                    "ownership_type": .string("PURCHASED"),
                    "period_type": .string("trial"),
                    "status": .string("paused"),
                    "price_amount_micros": .int(4_990_000),
                    "price_currency": .string("USD"),
                    "purchased_at": .date(Self.date("2024-05-01T00:00:00Z")),
                    "original_purchased_at": .date(Self.date("2021-01-01T00:00:00Z")),
                    "expires_at": .date(Self.date("2100-01-01T00:00:00Z")),
                    "unsubscribe_detected_at": .date(Self.date("2024-05-03T00:00:00Z")),
                    "billing_issue_detected_at": .date(Self.date("2024-05-04T00:00:00Z")),
                    "grace_period_expires_at": .date(Self.date("2024-05-10T00:00:00Z")),
                    "refunded_at": .date(Self.date("2024-05-05T00:00:00Z")),
                    "auto_resume_at": .date(Self.date("2024-07-01T00:00:00Z")),
                    "is_active": .bool(true),
                    "is_sandbox": .bool(true),
                    "will_renew": .bool(false),
                    "is_in_grace_period": .bool(false),
                    "is_refunded": .bool(true),
                    "is_paused": .bool(true)
                ],
                [
                    "kind": .string("non_subscription"),
                    "product_identifier": .string("coins"),
                    "purchased_product_identifier": .string("coins"),
                    "transaction_identifier": .string("rc_transaction_id"),
                    "store_transaction_id": .string("2000000987654321"),
                    "display_name": .string("100 Coins"),
                    "store": .string("app_store"),
                    "price_amount_micros": .int(1_990_000),
                    "price_currency": .string("EUR"),
                    "purchased_at": .date(Self.date("2023-03-03T00:00:00Z")),
                    "original_purchased_at": .date(Self.date("2023-03-01T00:00:00Z")),
                    "is_sandbox": .bool(false)
                ]
            ]),
            "entitlements": .objectList([
                [
                    "identifier": .string("premium"),
                    "product_identifier": .string("premium"),
                    "product_plan_identifier": .string("monthly"),
                    "purchased_product_identifier": .string("premium:monthly"),
                    "store": .string("app_store"),
                    "ownership_type": .string("PURCHASED"),
                    "period_type": .string("trial"),
                    "latest_purchased_at": .date(Self.date("2024-05-01T00:00:00Z")),
                    "original_purchased_at": .date(Self.date("2021-01-01T00:00:00Z")),
                    "expires_at": .date(Self.date("2100-01-01T00:00:00Z")),
                    "unsubscribe_detected_at": .date(Self.date("2024-05-03T00:00:00Z")),
                    "billing_issue_detected_at": .date(Self.date("2024-05-04T00:00:00Z")),
                    "is_active": .bool(true),
                    "is_sandbox": .bool(true),
                    "will_renew": .bool(false)
                ]
            ])
        ])
    }

    @Test
    func fetchesCustomerInfoForTheSingleCapturedAppUserID() async throws {
        let receivedAppUserID = Atomic<String?>(nil)
        let provider = CustomerInfoDimensionProvider(
            currentAppUserIDProvider: { Self.appUserID },
            customerInfoProvider: { appUserID in
                receivedAppUserID.modify { $0 = appUserID }
                return try Self.customerInfo()
            }
        )

        _ = try await provider.dimensions(at: Self.evaluationDate)

        #expect(receivedAppUserID.value == Self.appUserID)
    }

    @Test
    func emptyAppUserIDContributesNothingWithoutFetchingCustomerInfo() async throws {
        let fetchCount = Atomic(0)
        let provider = CustomerInfoDimensionProvider(
            currentAppUserIDProvider: { "" },
            customerInfoProvider: { _ in
                fetchCount.modify { $0 += 1 }
                return try Self.customerInfo()
            }
        )

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(dimensions.isEmpty)
        #expect(fetchCount.value == 0)
    }

    @Test
    func unavailableCustomerInfoStillExposesTheCurrentAppUserID() async throws {
        let provider = CustomerInfoDimensionProvider(
            currentAppUserIDProvider: { Self.appUserID },
            customerInfoProvider: { _ in throw TestError.customerInfoUnavailable }
        )

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(dimensions == ["app_user_id": .string(Self.appUserID)])
    }

    @Test
    func cancellationPropagates() async {
        let provider = CustomerInfoDimensionProvider(
            currentAppUserIDProvider: { Self.appUserID },
            customerInfoProvider: { _ in throw CancellationError() }
        )

        await #expect(throws: CancellationError.self) {
            _ = try await provider.dimensions(at: Self.evaluationDate)
        }
    }

    @Test
    func propertiesCanBeEvaluatedUsingCanonicalPaths() async throws {
        let evaluator = LocalRulesEvaluator(dimensionProviders: [Self.provider()])
        let predicates = [
            #"{"==":[{"var":"app_user_id"},"current_user"]}"#,
            #"{"some":[{"var":"purchases"},{"and":[{"==":[{"var":"kind"},"subscription"]},{"var":"is_active"}]}]}"#,
            #"{"some":[{"var":"entitlements"},{"and":[{"==":[{"var":"identifier"},"premium"]},{"var":"is_active"}]}]}"#
        ]

        for predicate in predicates {
            let match = try await evaluator.match(in: [TestRule(predicate: predicate)])
            #expect(match != nil, Comment(rawValue: predicate))
        }
    }

    @Test
    func expandedPurchasePropertiesCanBeEvaluatedUsingCanonicalPaths() async throws {
        let evaluator = LocalRulesEvaluator(dimensionProviders: [Self.provider()])
        let predicate = #"""
        {
            "some": [
                { "var": "purchases" },
                {
                    "and": [
                        { "==": [{ "var": "purchased_product_identifier" }, "premium:monthly"] },
                        { ">": [{ "var": "expires_at" }, 4000000000000] },
                        { "==": [{ "var": ["missing_property", "fallback"] }, "fallback"] }
                    ]
                }
            ]
        }
        """#

        let match = try await evaluator.match(in: [TestRule(predicate: predicate)])

        #expect(match != nil)
    }

    @Test
    func purchasesAreOrderedNewestFirstAndTiesAreDeterministic() async throws {
        let subscriptions: [String: Any] = [
            "zeta": Self.subscription(purchaseDate: "2024-05-01T00:00:00Z"),
            "alpha": Self.subscription(purchaseDate: "2024-05-01T00:00:00Z")
        ]
        let nonSubscriptions: [String: Any] = [
            "newest": [Self.nonSubscription(purchaseDate: "2024-06-01T00:00:00Z")]
        ]
        let provider = Self.provider(
            customerInfoData: Self.customerInfoData(
                subscriptions: subscriptions,
                nonSubscriptions: nonSubscriptions
            )
        )

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(Self.productIdentifiers(from: dimensions) == ["newest", "alpha", "zeta"])
    }

    @Test
    func mapsEveryStoreAndOmitsAnUnknownStore() async throws {
        let stores: [(rawValue: Any, expected: String?)] = [
            ("app_store", "app_store"),
            ("mac_app_store", "mac_app_store"),
            ("play_store", "play_store"),
            ("stripe", "stripe"),
            ("promotional", "promotional"),
            (NSNull(), nil),
            ("amazon", "amazon"),
            ("rc_billing", "rc_billing"),
            ("external", "external"),
            ("paddle", "paddle"),
            ("test_store", "test_store"),
            ("galaxy", "galaxy")
        ]
        let subscriptions = stores.enumerated().reduce(into: [String: Any]()) { result, element in
            result[String(format: "product_%02d", element.offset)] = Self.subscription(store: element.element.rawValue)
        }
        let provider = Self.provider(customerInfoData: Self.customerInfoData(subscriptions: subscriptions))

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)
        let purchases = Self.purchasesByProductIdentifier(from: dimensions)

        for (index, store) in stores.enumerated() {
            let identifier = String(format: "product_%02d", index)
            #expect(purchases[identifier]?["store"] == store.expected.map(DimensionValue.string))
        }
    }

    @Test
    func mapsEverySubscriptionPeriodType() async throws {
        let periodTypes = ["normal", "intro", "trial", "prepaid"]
        let subscriptions = periodTypes.enumerated().reduce(into: [String: Any]()) { result, element in
            result["product_\(element.offset)"] = Self.subscription(periodType: element.element)
        }
        let provider = Self.provider(customerInfoData: Self.customerInfoData(subscriptions: subscriptions))

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)
        let purchases = Self.purchasesByProductIdentifier(from: dimensions)

        for (index, periodType) in periodTypes.enumerated() {
            #expect(purchases["product_\(index)"]?["period_type"] == .string(periodType))
        }
    }

    @Test
    func emptyCustomerInfoCollectionsRemainReadableAndAnEmptyOriginalAppUserIDIsOmitted() async throws {
        let provider = Self.provider(
            customerInfoData: Self.customerInfoData(originalAppUserID: "")
        )

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(dimensions == [
            "app_user_id": .string(Self.appUserID),
            "first_seen_at": .date(Self.date("2022-01-01T00:00:00Z")),
            "purchases": .objectList([]),
            "entitlements": .objectList([])
        ])
    }

}

extension CustomerInfoDimensionProviderTests {

    @Test
    func mapsKnownOwnershipTypesAndOmitsUnknownOwnership() async throws {
        let ownershipTypes: [(rawValue: String, expected: String?)] = [
            ("PURCHASED", "PURCHASED"),
            ("FAMILY_SHARED", "FAMILY_SHARED"),
            ("UNKNOWN", nil)
        ]
        let subscriptions = ownershipTypes.enumerated().reduce(into: [String: Any]()) { result, element in
            result["product_\(element.offset)"] = Self.subscription(ownershipType: element.element.rawValue)
        }
        let provider = Self.provider(customerInfoData: Self.customerInfoData(subscriptions: subscriptions))

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)
        let purchases = Self.purchasesByProductIdentifier(from: dimensions)

        for (index, ownershipType) in ownershipTypes.enumerated() {
            #expect(
                purchases["product_\(index)"]?["ownership_type"]
                    == ownershipType.expected.map(DimensionValue.string)
            )
        }
    }

    @Test
    func derivesEverySubscriptionLifecycleStatus() async throws {
        let cases: [(label: String, expected: String, subscription: [String: Any])] = [
            ("active", "active", Self.subscription()),
            ("trial", "trialing", Self.subscription(periodType: "trial")),
            (
                "grace period",
                "in_grace_period",
                Self.subscription(
                    expiresDate: "2024-05-01T00:00:00Z",
                    billingIssuesDetectedAt: "2024-05-02T00:00:00Z",
                    gracePeriodExpiresDate: "2024-07-01T00:00:00Z"
                )
            ),
            ("paused", "paused", Self.subscription(autoResumeDate: "2024-07-01T00:00:00Z")),
            ("expired", "expired", Self.subscription(expiresDate: "2024-05-01T00:00:00Z"))
        ]

        for testCase in cases {
            let provider = Self.provider(
                customerInfoData: Self.customerInfoData(subscriptions: ["premium": testCase.subscription])
            )

            let dimensions = try await provider.dimensions(at: Self.evaluationDate)
            let purchase = Self.purchasesByProductIdentifier(from: dimensions)["premium"]

            #expect(purchase?["status"] == .string(testCase.expected), Comment(rawValue: testCase.label))
        }
    }

    @Test
    func lifetimeSubscriptionHasNoExpiryAndRemainsActiveWithoutRenewing() async throws {
        let provider = Self.provider(
            customerInfoData: Self.customerInfoData(
                subscriptions: ["lifetime": Self.subscription(expiresDate: NSNull())]
            )
        )

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)
        let purchase = Self.purchasesByProductIdentifier(from: dimensions)["lifetime"]

        #expect(purchase?["expires_at"] == nil)
        #expect(purchase?["status"] == .string("active"))
        #expect(purchase?["is_active"] == .bool(true))
        #expect(purchase?["will_renew"] == .bool(false))
    }

    @Test
    func gracePeriodUsesTheEvaluationDateAndKeepsStatusAndFlagConsistent() async throws {
        let cases: [(expiry: String, isInGracePeriod: Bool, status: String)] = [
            ("2024-06-15T11:59:59Z", false, "expired"),
            ("2024-06-15T12:00:00Z", false, "expired"),
            ("2024-06-15T12:00:01Z", true, "in_grace_period")
        ]

        for testCase in cases {
            let subscription = Self.subscription(
                periodType: "trial",
                expiresDate: "2024-05-01T00:00:00Z",
                billingIssuesDetectedAt: "2024-05-02T00:00:00Z",
                gracePeriodExpiresDate: testCase.expiry
            )
            let provider = Self.provider(
                customerInfoData: Self.customerInfoData(subscriptions: ["premium": subscription])
            )

            let dimensions = try await provider.dimensions(at: Self.evaluationDate)
            let purchase = Self.purchasesByProductIdentifier(from: dimensions)["premium"]

            #expect(purchase?["status"] == .string(testCase.status))
            #expect(purchase?["is_in_grace_period"] == .bool(testCase.isInGracePeriod))
            #expect(purchase?["is_active"] == .bool(false))
        }
    }

    @Test
    func exposesBothValuesForSubscriptionLifecycleFlags() async throws {
        let activeProvider = Self.provider(
            customerInfoData: Self.customerInfoData(subscriptions: ["premium": Self.subscription()])
        )
        let activeDimensions = try await activeProvider.dimensions(at: Self.evaluationDate)
        let activePurchase = Self.purchasesByProductIdentifier(from: activeDimensions)["premium"]

        #expect(activePurchase?["will_renew"] == .bool(true))
        #expect(activePurchase?["is_in_grace_period"] == .bool(false))
        #expect(activePurchase?["is_refunded"] == .bool(false))
        #expect(activePurchase?["is_paused"] == .bool(false))

        var affectedSubscription = Self.subscription(
            expiresDate: "2024-05-01T00:00:00Z",
            gracePeriodExpiresDate: "2024-07-01T00:00:00Z",
            autoResumeDate: "2024-07-01T00:00:00Z"
        )
        affectedSubscription["refunded_at"] = "2024-05-05T00:00:00Z"
        let affectedProvider = Self.provider(
            customerInfoData: Self.customerInfoData(subscriptions: ["premium": affectedSubscription])
        )
        let affectedDimensions = try await affectedProvider.dimensions(at: Self.evaluationDate)
        let affectedPurchase = Self.purchasesByProductIdentifier(from: affectedDimensions)["premium"]

        #expect(affectedPurchase?["is_in_grace_period"] == .bool(true))
        #expect(affectedPurchase?["is_refunded"] == .bool(true))
        #expect(affectedPurchase?["is_paused"] == .bool(true))
    }

}

extension CustomerInfoDimensionProviderTests {

    @Test
    func fetchesFreshCustomerInfoForEveryEvaluation() async throws {
        let fetchCount = Atomic(0)
        let provider = CustomerInfoDimensionProvider(
            currentAppUserIDProvider: { Self.appUserID },
            customerInfoProvider: { _ in
                let count: Int = fetchCount.modify { $0 += 1; return $0 }
                let subscriptions = count == 1 ? [:] : ["premium": Self.subscription()]
                return try CustomerInfo(data: Self.customerInfoData(subscriptions: subscriptions))
            }
        )

        let firstDimensions = try await provider.dimensions(at: Self.evaluationDate)
        let secondDimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(Self.productIdentifiers(from: firstDimensions).isEmpty)
        #expect(Self.productIdentifiers(from: secondDimensions) == ["premium"])
        #expect(fetchCount.value == 2)
    }

    @Test
    func convertsPricesToMicrosUsingNearestRounding() async throws {
        let cases: [(amount: Double, expectedMicros: Int64)] = [
            (1.234567, 1_234_567),
            (0.0000005, 1)
        ]

        for (index, testCase) in cases.enumerated() {
            var subscription = Self.subscription()
            subscription["price"] = ["amount": testCase.amount, "currency": "USD"]
            let identifier = "product_\(index)"
            let provider = Self.provider(
                customerInfoData: Self.customerInfoData(subscriptions: [identifier: subscription])
            )

            let dimensions = try await provider.dimensions(at: Self.evaluationDate)
            let purchase = Self.purchasesByProductIdentifier(from: dimensions)[identifier]

            #expect(purchase?["price_amount_micros"] == .int(testCase.expectedMicros))
        }
    }

    @Test
    func entitlementsAreOrderedAndExposeNonDefaultValues() async throws {
        let subscriptions: [String: Any] = [
            "zeta_product": Self.subscription(),
            "alpha_product": Self.subscription(
                expiresDate: "2024-05-01T00:00:00Z",
                ownershipType: "FAMILY_SHARED"
            )
        ]
        let entitlements: [String: Any] = [
            "zeta": Self.entitlement(productIdentifier: "zeta_product"),
            "alpha": Self.entitlement(
                productIdentifier: "alpha_product",
                expiresDate: "2024-05-01T00:00:00Z"
            )
        ]
        let provider = Self.provider(
            customerInfoData: Self.customerInfoData(
                subscriptions: subscriptions,
                entitlements: entitlements
            )
        )

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)
        let entitlementValues = Self.entitlements(from: dimensions)

        #expect(entitlementValues.compactMap(Self.identifier(from:)) == ["alpha", "zeta"])
        #expect(entitlementValues[0]["is_active"] == .bool(false))
        #expect(entitlementValues[0]["ownership_type"] == .string("FAMILY_SHARED"))
    }

}

private extension CustomerInfoDimensionProviderTests {

    static func provider() -> CustomerInfoDimensionProvider {
        return Self.provider(customerInfoData: Self.customerInfoData)
    }

    static func provider(customerInfoData: [String: Any]) -> CustomerInfoDimensionProvider {
        return CustomerInfoDimensionProvider(
            currentAppUserIDProvider: { Self.appUserID },
            customerInfoProvider: { _ in try CustomerInfo(data: customerInfoData) }
        )
    }

    private static func customerInfo() throws -> CustomerInfo {
        return try CustomerInfo(data: Self.customerInfoData)
    }

    private static let appUserID = "current_user"
    private static let evaluationDate = Date(timeIntervalSince1970: 1_718_452_800)

    private static func customerInfoData(
        originalAppUserID: String = "original_user",
        subscriptions: [String: Any] = [:],
        nonSubscriptions: [String: Any] = [:],
        entitlements: [String: Any] = [:]
    ) -> [String: Any] {
        return [
            "request_date": "2024-06-01T00:00:00Z",
            "subscriber": [
                "first_seen": "2022-01-01T00:00:00Z",
                "original_app_user_id": originalAppUserID,
                "original_application_version": "1.0",
                "non_subscriptions": nonSubscriptions,
                "subscriptions": subscriptions,
                "entitlements": entitlements
            ]
        ]
    }

    private static func subscription(
        store: Any = "app_store",
        purchaseDate: String = "2024-05-01T00:00:00Z",
        periodType: String = "normal",
        expiresDate: Any = "2100-01-01T00:00:00Z",
        billingIssuesDetectedAt: String? = nil,
        gracePeriodExpiresDate: String? = nil,
        autoResumeDate: String? = nil,
        ownershipType: String = "PURCHASED"
    ) -> [String: Any] {
        return [
            "store": store,
            "purchase_date": purchaseDate,
            "original_purchase_date": "2021-01-01T00:00:00Z",
            "expires_date": expiresDate,
            "period_type": periodType,
            "is_sandbox": true,
            "ownership_type": ownershipType,
            "billing_issues_detected_at": billingIssuesDetectedAt ?? NSNull(),
            "grace_period_expires_date": gracePeriodExpiresDate ?? NSNull(),
            "auto_resume_date": autoResumeDate ?? NSNull()
        ]
    }

    private static func nonSubscription(purchaseDate: String) -> [String: Any] {
        return [
            "id": "rc_transaction_id",
            "store_transaction_id": "2000000987654321",
            "is_sandbox": false,
            "original_purchase_date": purchaseDate,
            "purchase_date": purchaseDate,
            "store": "app_store"
        ]
    }

    private static func entitlement(
        productIdentifier: String,
        expiresDate: String = "2100-01-01T00:00:00Z"
    ) -> [String: Any] {
        return [
            "expires_date": expiresDate,
            "product_identifier": productIdentifier,
            "purchase_date": "2024-05-01T00:00:00Z"
        ]
    }

    private static func productIdentifiers(from dimensions: [String: DimensionValue]) -> [String] {
        guard case let .objectList(purchases) = dimensions["purchases"] else { return [] }

        return purchases.compactMap { purchase in
            guard case let .string(identifier) = purchase["product_identifier"] else { return nil }
            return identifier
        }
    }

    private static func purchasesByProductIdentifier(
        from dimensions: [String: DimensionValue]
    ) -> [String: [String: DimensionValue]] {
        guard case let .objectList(purchases) = dimensions["purchases"] else { return [:] }

        return purchases.reduce(into: [:]) { result, purchase in
            guard case let .string(identifier) = purchase["product_identifier"] else { return }
            result[identifier] = purchase
        }
    }

    private static func entitlements(from dimensions: [String: DimensionValue]) -> [[String: DimensionValue]] {
        guard case let .objectList(entitlements) = dimensions["entitlements"] else { return [] }
        return entitlements
    }

    private static func identifier(from values: [String: DimensionValue]) -> String? {
        guard case let .string(identifier) = values["identifier"] else { return nil }
        return identifier
    }

    static func date(_ value: String) -> Date {
        guard let date = ISO8601DateFormatter.default.date(from: value) else {
            preconditionFailure("Invalid test date: \(value)")
        }
        return date
    }

    private static let customerInfoData: [String: Any] = [
        "request_date": "2024-06-01T00:00:00Z",
        "subscriber": [
            "first_seen": "2022-01-01T00:00:00Z",
            "original_app_user_id": "original_user",
            "original_application_version": "1.0",
            "original_purchase_date": "2021-01-01T00:00:00Z",
            "non_subscriptions": [
                "coins": [[
                    "id": "rc_transaction_id",
                    "store_transaction_id": "2000000987654321",
                    "is_sandbox": false,
                    "original_purchase_date": "2023-03-01T00:00:00Z",
                    "purchase_date": "2023-03-03T00:00:00Z",
                    "store": "app_store",
                    "display_name": "100 Coins",
                    "price": ["amount": 1.99, "currency": "EUR"]
                ]]
            ],
            "subscriptions": [
                "premium": [
                    "store": "app_store",
                    "purchase_date": "2024-05-01T00:00:00Z",
                    "original_purchase_date": "2021-01-01T00:00:00Z",
                    "expires_date": "2100-01-01T00:00:00Z",
                    "period_type": "trial",
                    "is_sandbox": true,
                    "ownership_type": "PURCHASED",
                    "product_plan_identifier": "monthly",
                    "store_transaction_id": "2000000123456789",
                    "display_name": "Premium Monthly",
                    "price": ["amount": 4.99, "currency": "USD"],
                    "unsubscribe_detected_at": "2024-05-03T00:00:00Z",
                    "billing_issues_detected_at": "2024-05-04T00:00:00Z",
                    "grace_period_expires_date": "2024-05-10T00:00:00Z",
                    "refunded_at": "2024-05-05T00:00:00Z",
                    "auto_resume_date": "2024-07-01T00:00:00Z"
                ]
            ],
            "entitlements": [
                "premium": [
                    "expires_date": "2100-01-01T00:00:00Z",
                    "product_identifier": "premium",
                    "purchase_date": "2024-05-01T00:00:00Z"
                ]
            ]
        ]
    ]

}

private extension CustomerInfoDimensionProviderTests {

    struct TestRule: LocalRule {

        let id = "test_rule"
        let predicate: String
    }

    enum TestError: Error {

        case customerInfoUnavailable
    }

}
