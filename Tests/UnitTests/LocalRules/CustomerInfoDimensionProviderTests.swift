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

struct CustomerInfoDimensionProviderTests {

    @Test
    func exposesTheCustomerInfoScope() async throws {
        let provider = Self.provider()

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(provider.name == "customer_info")
        #expect(dimensions == [
            "app_user_id": .string(Self.appUserID),
            "original_app_user_id": .string("original_user"),
            "purchases": .objectList([
                [
                    "kind": .string("subscription"),
                    "is_active": .bool(true),
                    "is_sandbox": .bool(true),
                    "store": .string("app_store"),
                    "product_identifier": .string("premium"),
                    "period_type": .string("trial")
                ],
                [
                    "kind": .string("non_subscription"),
                    "is_sandbox": .bool(false),
                    "store": .string("app_store"),
                    "product_identifier": .string("coins")
                ]
            ]),
            "entitlements": .objectList([
                [
                    "identifier": .string("premium"),
                    "is_active": .bool(true),
                    "is_sandbox": .bool(true)
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
            "purchases": .objectList([]),
            "entitlements": .objectList([])
        ])
    }

    private static func provider() -> CustomerInfoDimensionProvider {
        return Self.provider(customerInfoData: Self.customerInfoData)
    }

    private static func provider(customerInfoData: [String: Any]) -> CustomerInfoDimensionProvider {
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
        periodType: String = "normal"
    ) -> [String: Any] {
        return [
            "store": store,
            "purchase_date": purchaseDate,
            "original_purchase_date": "2021-01-01T00:00:00Z",
            "expires_date": "2100-01-01T00:00:00Z",
            "period_type": periodType,
            "is_sandbox": true
        ]
    }

    private static func nonSubscription(purchaseDate: String) -> [String: Any] {
        return [
            "id": "transaction_id",
            "store_transaction_id": "store_transaction_id",
            "is_sandbox": false,
            "original_purchase_date": purchaseDate,
            "purchase_date": purchaseDate,
            "store": "app_store"
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

    private static let customerInfoData: [String: Any] = [
        "request_date": "2024-06-01T00:00:00Z",
        "subscriber": [
            "first_seen": "2022-01-01T00:00:00Z",
            "original_app_user_id": "original_user",
            "original_application_version": "1.0",
            "non_subscriptions": [
                "coins": [[
                    "id": "transaction_id",
                    "store_transaction_id": "store_transaction_id",
                    "is_sandbox": false,
                    "original_purchase_date": "2023-03-03T00:00:00Z",
                    "purchase_date": "2023-03-03T00:00:00Z",
                    "store": "app_store"
                ]]
            ],
            "subscriptions": [
                "premium": [
                    "store": "app_store",
                    "purchase_date": "2024-05-01T00:00:00Z",
                    "original_purchase_date": "2021-01-01T00:00:00Z",
                    "expires_date": "2100-01-01T00:00:00Z",
                    "period_type": "trial",
                    "is_sandbox": true
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
