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
//  Created by Facundo Menzella on 8/20/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Customer info dimension provider")
struct CustomerInfoDimensionProviderTests {

    @Test
    func exposesTheCustomersIdentityAndLifecycle() async throws {
        let dimensions = try await Self.provider().dimensions(in: Self.context)

        #expect(dimensions["appUserId"] == .string("current_user"))
        #expect(dimensions["originalAppUserId"] == .string("original_user"))
        #expect(dimensions["firstSeenAt"] == .date(Self.firstSeenDate))
        #expect(dimensions["lastSeenAt"] == .date(Self.requestDate))
        #expect(dimensions["originalPurchasedAt"] == .date(Self.originalPurchaseDate))
    }

    @Test
    func describesEveryPurchaseOfEitherKindNewestFirst() async throws {
        let purchases = try await Self.purchases(of: Self.provider())

        #expect(purchases.map { $0["purchasedProductIdentifier"] } == [
            .string("premium:monthly"),
            .string("coins")
        ])
        #expect(purchases.map { $0["kind"] } == [
            .string("subscription"),
            .string("nonSubscription")
        ])
    }

    @Test
    func describesASubscriptionWithEverythingTheSDKKnowsAboutIt() async throws {
        let subscription = try await Self.purchase(withProductIdentifier: "premium", of: Self.provider())

        #expect(subscription == [
            "kind": .string("subscription"),
            "productIdentifier": .string("premium"),
            "productPlanIdentifier": .string("monthly"),
            "purchasedProductIdentifier": .string("premium:monthly"),
            "storeTransactionId": .string("GPA.0000-0000-0000-00000"),
            "displayName": .string("Premium Monthly"),
            "store": .string("play_store"),
            "ownershipType": .string("PURCHASED"),
            "periodType": .string("trial"),
            "status": .string("paused"),
            "priceAmountMicros": .int(4_990_000),
            "priceCurrency": .string("USD"),
            "purchasedAt": .date(Self.subscriptionPurchaseDate),
            "originalPurchasedAt": .date(Self.originalPurchaseDate),
            "expiresAt": .date(Self.distantExpiryDate),
            "unsubscribeDetectedAt": .date(Self.unsubscribeDetectedDate),
            "billingIssueDetectedAt": .date(Self.billingIssueDetectedDate),
            "gracePeriodExpiresAt": .date(Self.expiredGracePeriodDate),
            "refundedAt": .date(Self.refundedDate),
            "autoResumeAt": .date(Self.autoResumeDate),
            "isSandbox": .bool(true),
            "isActive": .bool(true),
            "willRenew": .bool(false),
            "isInGracePeriod": .bool(false),
            "isRefunded": .bool(true),
            "isPaused": .bool(true)
        ])
    }

    @Test
    func describesAOneTimePurchaseWithoutTheFieldsOnlyASubscriptionHas() async throws {
        let transaction = try await Self.purchase(withProductIdentifier: "coins", of: Self.provider())

        #expect(transaction == [
            "kind": .string("nonSubscription"),
            "productIdentifier": .string("coins"),
            "purchasedProductIdentifier": .string("coins"),
            "transactionIdentifier": .string("abc123"),
            "storeTransactionId": .string("amzn.1234"),
            "store": .string("amazon"),
            "priceAmountMicros": .int(1_990_000),
            "priceCurrency": .string("EUR"),
            "purchasedAt": .date(Self.transactionPurchaseDate),
            "isSandbox": .bool(false)
        ])
    }

    @Test
    func describesEveryEntitlementOrderedByIdentifier() async throws {
        let entitlements = try await Self.entitlements(of: Self.provider())

        #expect(entitlements.map { $0["identifier"] } == [.string("extra"), .string("premium")])
        #expect(entitlements.first == [
            "identifier": .string("extra"),
            "productIdentifier": .string("premium"),
            "productPlanIdentifier": .string("monthly"),
            "purchasedProductIdentifier": .string("premium:monthly"),
            "store": .string("play_store"),
            "ownershipType": .string("PURCHASED"),
            "periodType": .string("trial"),
            "latestPurchasedAt": .date(Self.subscriptionPurchaseDate),
            "originalPurchasedAt": .date(Self.originalPurchaseDate),
            "expiresAt": .date(Self.distantExpiryDate),
            "unsubscribeDetectedAt": .date(Self.unsubscribeDetectedDate),
            "billingIssueDetectedAt": .date(Self.billingIssueDetectedDate),
            "isSandbox": .bool(true),
            "isActive": .bool(true),
            "willRenew": .bool(false)
        ])
    }

    @Test
    func reportsWhereTheCustomerIsInEachSubscriptionsLifecycle() async throws {
        let lifecycles: [(subscription: [String: Any], status: String)] = [
            (Self.subscription(periodType: "normal"), "active"),
            (Self.subscription(periodType: "intro"), "active"),
            (Self.subscription(periodType: "trial"), "trialing"),
            (Self.subscription(expiresDate: Self.lapsedExpiryDate), "expired"),
            (
                Self.subscription(expiresDate: Self.lapsedExpiryDate, gracePeriodExpiresDate: Self.distantExpiryDate),
                "in_grace_period"
            ),
            (Self.subscription(autoResumeDate: Self.autoResumeDate), "paused")
        ]

        for lifecycle in lifecycles {
            let provider = Self.provider(
                subscriptions: ["premium": lifecycle.subscription],
                entitlements: [:]
            )

            let purchase = try await Self.purchase(withProductIdentifier: "premium", of: provider)

            #expect(purchase["status"] == .string(lifecycle.status))
        }
    }

    @Test
    func theGracePeriodStatusAndTheGracePeriodFlagAlwaysAgree() async throws {
        let provider = Self.provider(
            subscriptions: [
                "premium": Self.subscription(
                    expiresDate: Self.lapsedExpiryDate,
                    gracePeriodExpiresDate: Self.distantExpiryDate
                )
            ],
            entitlements: [:]
        )

        let purchase = try await Self.purchase(withProductIdentifier: "premium", of: provider)

        #expect(purchase["status"] == .string("in_grace_period"))
        #expect(purchase["isInGracePeriod"] == .bool(true))
    }

    @Test
    func aOneTimePurchaseHasNoStatusSinceOnlyASubscriptionHasALifecycle() async throws {
        let transaction = try await Self.purchase(withProductIdentifier: "coins", of: Self.provider())

        #expect(transaction["status"] == nil)
        #expect(transaction["isActive"] == nil)
        #expect(transaction["expiresAt"] == nil)
        #expect(transaction["willRenew"] == nil)
    }

    @Test
    func aCustomerWhoHasNeverBoughtAnythingReportsEmptyCollectionsRatherThanNone() async throws {
        let provider = Self.provider(subscriptions: [:], nonSubscriptions: [:], entitlements: [:])

        let dimensions = try await provider.dimensions(in: Self.context)

        #expect(dimensions["purchases"] == .objectList([]))
        #expect(dimensions["entitlements"] == .objectList([]))
    }

    @Test
    func aLifetimePurchaseReportsNoExpiryAndStaysActive() async throws {
        let provider = Self.provider(
            subscriptions: ["lifetime": Self.subscription(expiresDate: nil)],
            entitlements: [:]
        )

        let purchase = try await Self.purchase(withProductIdentifier: "lifetime", of: provider)

        #expect(purchase["expiresAt"] == nil)
        #expect(purchase["isActive"] == .bool(true))
        #expect(purchase["status"] == .string("active"))
    }

    @Test
    func anUnknownOwnershipTypeIsReportedAsNoOwnershipTypeAtAll() async throws {
        let provider = Self.provider(
            subscriptions: ["premium": Self.subscription(ownershipType: "SOMETHING_ELSE")],
            entitlements: [:]
        )

        let purchase = try await Self.purchase(withProductIdentifier: "premium", of: provider)

        #expect(purchase["ownershipType"] == nil)
    }

    @Test
    func reportsPricesAsWholeMillionthsOfACurrencyUnit() async throws {
        let provider = Self.provider(
            subscriptions: ["premium": Self.subscription(price: ["currency": "USD", "amount": 0.1])],
            entitlements: [:]
        )

        let purchase = try await Self.purchase(withProductIdentifier: "premium", of: provider)

        #expect(purchase["priceAmountMicros"] == .int(100_000))
        #expect(purchase["priceCurrency"] == .string("USD"))
    }

    @Test
    func ordersPurchasesSharingAPurchaseDateByProduct() async throws {
        let productIdentifiers = (1...8).map { "product_\($0)" }
        let provider = Self.provider(
            subscriptions: productIdentifiers.reduce(into: [:]) { subscriptions, productIdentifier in
                subscriptions[productIdentifier] = Self.subscription()
            },
            nonSubscriptions: [:],
            entitlements: [:]
        )

        let purchases = try await Self.purchases(of: provider)

        #expect(purchases.map { $0["productIdentifier"] } == productIdentifiers.map { .string($0) })
    }

    @Test
    func ordersOneTimePurchasesSharingAPurchaseDateByProduct() async throws {
        let purchasedAt = Self.string(from: Self.transactionPurchaseDate)
        let provider = Self.provider(
            subscriptions: [:],
            nonSubscriptions: [
                "gems": Self.transaction(id: "t2", purchasedAt: purchasedAt),
                "coins": Self.transaction(id: "t1", purchasedAt: purchasedAt),
                "keys": Self.transaction(id: "t3", purchasedAt: purchasedAt)
            ],
            entitlements: [:]
        )

        let purchases = try await Self.purchases(of: provider)

        #expect(purchases.map { $0["productIdentifier"] } == [
            .string("coins"),
            .string("gems"),
            .string("keys")
        ])
    }

    @Test
    func readsTheGracePeriodFromTheEvaluationDateEvenOnAStaleCustomerInfo() async throws {
        // Cached long before the evaluation. `isActive` and `willRenew` are not asserted here on
        // purpose: `CustomerInfo.isDateActive` falls back to the wall clock once the request date is
        // older than its three day grace window, so they do not follow the evaluation date the way
        // the values this provider derives do.
        let cachedAt = Self.date("2026-05-15T00:00:00Z")
        let provider = Self.provider(
            subscriptions: [
                "premium": Self.subscription(
                    expiresDate: Self.lapsedExpiryDate,
                    gracePeriodExpiresDate: Self.distantExpiryDate
                )
            ],
            entitlements: [:],
            requestDate: cachedAt
        )

        let purchase = try await Self.purchase(withProductIdentifier: "premium", of: provider)

        #expect(purchase["isInGracePeriod"] == .bool(true))
        #expect(purchase["status"] == .string("in_grace_period"))
    }

    @Test
    func closesTheGracePeriodOnceTheEvaluationDatePassesIt() async throws {
        let cachedAt = Self.date("2026-05-15T00:00:00Z")
        let provider = Self.provider(
            subscriptions: [
                "premium": Self.subscription(
                    expiresDate: Self.lapsedExpiryDate,
                    gracePeriodExpiresDate: Self.expiredGracePeriodDate
                )
            ],
            entitlements: [:],
            requestDate: cachedAt
        )

        let purchase = try await Self.purchase(withProductIdentifier: "premium", of: provider)

        #expect(purchase["isInGracePeriod"] == .bool(false))
        #expect(purchase["gracePeriodExpiresAt"] == .date(Self.expiredGracePeriodDate))
    }

    @Test
    func aCustomerInfoThatCannotBeReadLeavesTheIdentityDimensionsUsable() async throws {
        let provider = CustomerInfoDimensionProvider(
            customerInfoProvider: { _ in throw ErrorUtils.offlineConnectionError() }
        )

        let dimensions = try await provider.dimensions(in: Self.context)

        #expect(dimensions == ["appUserId": .string("current_user")])
    }

    @Test
    func anEmptyAppUserIDLeavesTheRestOfTheDimensionsUsable() async throws {
        let context = DimensionContext(date: Self.evaluationDate, appUserID: "")

        let dimensions = try await Self.provider().dimensions(in: context)

        #expect(dimensions["appUserId"] == nil)
        #expect(dimensions["originalAppUserId"] == .string("original_user"))
    }

    @Test
    func readsAndReportsTheCustomerTheSnapshotIsFor() async throws {
        let requestedAppUserID: Atomic<String?> = .init(nil)
        let customerInfo = try Self.customerInfo()
        let provider = CustomerInfoDimensionProvider(customerInfoProvider: { appUserID in
            requestedAppUserID.value = appUserID
            return customerInfo
        })

        let dimensions = try await provider.dimensions(
            in: DimensionContext(date: Self.evaluationDate, appUserID: "user_a")
        )

        #expect(requestedAppUserID.value == "user_a")
        #expect(dimensions["appUserId"] == .string("user_a"))
    }

    @Test
    func describesOneCustomerEvenWhenTheUserChangesMidSnapshot() async throws {
        let currentAppUserID: Atomic<String> = .init("user_a")
        let customerInfo = try Self.customerInfo()

        // Reads the customer the snapshot pinned, and switches user while suspended, the way a
        // `logIn` completing during the customer info request would.
        let customerInfoProvider = CustomerInfoDimensionProvider(customerInfoProvider: { appUserID in
            currentAppUserID.value = "user_b"
            #expect(appUserID == "user_a")
            return customerInfo
        })
        let attributesProvider = SubscriberAttributesDimensionProvider { appUserID in
            [appUserID: SubscriberAttribute(withKey: appUserID, value: "seen")]
        }

        // Customer info first: it switches user while suspended, so a resolver that read the
        // current user once per provider would hand the attributes provider the new one.
        let snapshot = try await DimensionResolver(
            dimensionProviders: [customerInfoProvider, attributesProvider],
            dateProvider: MockDateProvider(stubbedNow: Self.evaluationDate),
            appUserIDProvider: { currentAppUserID.value }
        ).snapshot()

        // Both namespaces describe user_a, even though the current user is user_b by now.
        let describesOneCustomer = """
        {"and": [{"==": [{"var": "customerInfo.appUserId"}, "user_a"]}, \
        {"==": [{"var": "subscriberAttributes.user_a.value"}, "seen"]}]}
        """

        #expect(currentAppUserID.value == "user_b")
        #expect(
            RulesEngine.evaluate(predicate: describesOneCustomer, variables: snapshot.values)
            == .success(true)
        )
    }

    @Test
    func anUnreadableCustomerInfoLetsAbsenceRulesMatch() async throws {
        let provider = CustomerInfoDimensionProvider(
            customerInfoProvider: { _ in throw ErrorUtils.offlineConnectionError() }
        )
        let snapshot = try await DimensionResolver(
            dimensionProviders: [provider],
            dateProvider: MockDateProvider(stubbedNow: Self.evaluationDate),
            appUserIDProvider: { "current_user" }
        ).snapshot()

        let hasNoActivePurchase = """
        {"none": [{"var": "customerInfo.purchases"}, {"var": "isActive"}]}
        """

        // Documented rather than desired: in JSON Logic `none` over a missing source is true, so a
        // customer info this device could not read is indistinguishable from a customer who has
        // bought nothing. A rule that must not match in that case has to test the ID as well.
        #expect(
            RulesEngine.evaluate(predicate: hasNoActivePurchase, variables: snapshot.values) == .success(true)
        )
    }

    @Test
    func cancellationWhileReadingTheCustomerInfoPropagates() async throws {
        let provider = CustomerInfoDimensionProvider(
            customerInfoProvider: { _ in throw CancellationError() }
        )

        await #expect(throws: CancellationError.self) {
            try await provider.dimensions(in: Self.context)
        }
    }

    @Test
    func readsTheCustomerInfoOnEveryEvaluation() async throws {
        let reader = CountingCustomerInfoReader(customerInfo: try Self.customerInfo())
        let provider = CustomerInfoDimensionProvider(
            customerInfoProvider: { _ in await reader.read() }
        )

        _ = try await provider.dimensions(in: Self.context)
        _ = try await provider.dimensions(in: Self.context)

        #expect(await reader.readCount == 2)
    }

    @Test
    func makesTheRecordsSearchableByARule() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [Self.provider()],
            dateProvider: MockDateProvider(stubbedNow: Self.evaluationDate),
            appUserIDProvider: { "current_user" }
        ).snapshot()

        let hasAnActiveTrial = """
        {"some": [{"var": "customerInfo.purchases"}, \
        {"and": [{"var": "isActive"}, {"==": [{"var": "periodType"}, "trial"]}]}]}
        """
        let hasAnEntitlementCalledExtra = """
        {"some": [{"var": "customerInfo.entitlements"}, {"==": [{"var": "identifier"}, "extra"]}]}
        """

        #expect(RulesEngine.evaluate(predicate: hasAnActiveTrial, variables: snapshot.values) == .success(true))
        #expect(
            RulesEngine.evaluate(predicate: hasAnEntitlementCalledExtra, variables: snapshot.values)
            == .success(true)
        )
    }

    @Test
    func nestsEveryDimensionUnderTheCustomerInfoRoot() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [Self.provider()],
            dateProvider: MockDateProvider(stubbedNow: Self.evaluationDate),
            appUserIDProvider: { "current_user" }
        ).snapshot()

        let readsTheAppUserID = #"{"==": [{"var": "customerInfo.appUserId"}, "current_user"]}"#
        let readsTheNewestPurchase = """
        {"==": [{"var": "customerInfo.purchases.0.productIdentifier"}, "premium"]}
        """

        #expect(RulesEngine.evaluate(predicate: readsTheAppUserID, variables: snapshot.values) == .success(true))
        #expect(
            RulesEngine.evaluate(predicate: readsTheNewestPurchase, variables: snapshot.values) == .success(true)
        )
    }

}

// MARK: - Fixtures

private extension CustomerInfoDimensionProviderTests {

    static let evaluationDate = Self.date("2026-06-15T12:00:00Z")
    static let context = DimensionContext(date: Self.evaluationDate, appUserID: "current_user")
    static let requestDate = Self.date("2026-06-15T12:00:00Z")
    static let firstSeenDate = Self.date("2022-01-01T00:00:00Z")
    static let originalPurchaseDate = Self.date("2021-01-01T00:00:00Z")
    static let subscriptionPurchaseDate = Self.date("2026-05-01T00:00:00Z")
    static let transactionPurchaseDate = Self.date("2023-03-03T00:00:00Z")
    static let distantExpiryDate = Self.date("2100-01-01T00:00:00Z")
    static let lapsedExpiryDate = Self.date("2026-05-20T00:00:00Z")
    static let unsubscribeDetectedDate = Self.date("2026-05-03T00:00:00Z")
    static let billingIssueDetectedDate = Self.date("2026-05-04T00:00:00Z")
    static let expiredGracePeriodDate = Self.date("2026-05-10T00:00:00Z")
    static let refundedDate = Self.date("2026-05-05T00:00:00Z")
    static let autoResumeDate = Self.date("2026-06-20T00:00:00Z")

    static func provider(
        subscriptions: [String: Any]? = nil,
        nonSubscriptions: [String: Any]? = nil,
        entitlements: [String: Any]? = nil,
        requestDate: Date = Self.requestDate
    ) -> CustomerInfoDimensionProvider {
        // swiftlint:disable:next force_try
        let customerInfo = try! Self.customerInfo(
            subscriptions: subscriptions,
            nonSubscriptions: nonSubscriptions,
            entitlements: entitlements,
            requestDate: requestDate
        )

        return CustomerInfoDimensionProvider(customerInfoProvider: { _ in customerInfo })
    }

    static func customerInfo(
        subscriptions: [String: Any]? = nil,
        nonSubscriptions: [String: Any]? = nil,
        entitlements: [String: Any]? = nil,
        requestDate: Date = Self.requestDate
    ) throws -> CustomerInfo {
        return try CustomerInfo(data: [
            "request_date": Self.string(from: requestDate),
            "subscriber": [
                "original_app_user_id": "original_user",
                "first_seen": Self.string(from: Self.firstSeenDate),
                "original_purchase_date": Self.string(from: Self.originalPurchaseDate),
                "original_application_version": "1.0",
                "subscriptions": subscriptions ?? Self.defaultSubscriptions,
                "non_subscriptions": nonSubscriptions ?? Self.defaultNonSubscriptions,
                "entitlements": entitlements ?? Self.defaultEntitlements
            ] as [String: Any]
        ])
    }

    static let defaultSubscriptions: [String: Any] = [
        "premium": Self.subscription(
            productPlanIdentifier: "monthly",
            periodType: "trial",
            autoResumeDate: Self.autoResumeDate
        )
    ]

    static let defaultNonSubscriptions: [String: Any] = [
        "coins": [
            [
                "id": "abc123",
                "store_transaction_id": "amzn.1234",
                "purchase_date": Self.string(from: Self.transactionPurchaseDate),
                "original_purchase_date": Self.string(from: Self.transactionPurchaseDate),
                "store": "amazon",
                "is_sandbox": false,
                "display_name": "100 Coins",
                "price": ["currency": "EUR", "amount": 1.99]
            ] as [String: Any]
        ]
    ]

    static let defaultEntitlements: [String: Any] = [
        "premium": Self.entitlement(),
        "extra": Self.entitlement()
    ]

    static func entitlement(productIdentifier: String = "premium") -> [String: Any] {
        return [
            "product_identifier": productIdentifier,
            "purchase_date": Self.string(from: Self.subscriptionPurchaseDate),
            "expires_date": Self.string(from: Self.distantExpiryDate)
        ]
    }

    static func subscription(
        productPlanIdentifier: String? = nil,
        periodType: String = "normal",
        ownershipType: String = "PURCHASED",
        expiresDate: Date? = Self.distantExpiryDate,
        gracePeriodExpiresDate: Date? = Self.expiredGracePeriodDate,
        autoResumeDate: Date? = nil,
        price: [String: Any] = ["currency": "USD", "amount": 4.99]
    ) -> [String: Any] {
        var subscription: [String: Any] = [
            "period_type": periodType,
            "purchase_date": Self.string(from: Self.subscriptionPurchaseDate),
            "original_purchase_date": Self.string(from: Self.originalPurchaseDate),
            "store": "play_store",
            "is_sandbox": true,
            "unsubscribe_detected_at": Self.string(from: Self.unsubscribeDetectedDate),
            "billing_issues_detected_at": Self.string(from: Self.billingIssueDetectedDate),
            "ownership_type": ownershipType,
            "refunded_at": Self.string(from: Self.refundedDate),
            "store_transaction_id": "GPA.0000-0000-0000-00000",
            "display_name": "Premium Monthly",
            "price": price
        ]

        subscription["product_plan_identifier"] = productPlanIdentifier
        subscription["expires_date"] = expiresDate.map(Self.string(from:))
        subscription["grace_period_expires_date"] = gracePeriodExpiresDate.map(Self.string(from:))
        subscription["auto_resume_date"] = autoResumeDate.map(Self.string(from:))

        return subscription
    }

    static func transaction(id: String, purchasedAt: String) -> [[String: Any]] {
        return [[
            "id": id,
            "store_transaction_id": "store.\(id)",
            "purchase_date": purchasedAt,
            "store": "app_store",
            "is_sandbox": false
        ]]
    }

    static func date(_ string: String) -> Date {
        // swiftlint:disable:next force_unwrapping
        return ISO8601DateFormatter().date(from: string)!
    }

    static func string(from date: Date) -> String {
        return ISO8601DateFormatter().string(from: date)
    }

}

// MARK: - Reading records

private extension CustomerInfoDimensionProviderTests {

    static func purchases(of provider: CustomerInfoDimensionProvider) async throws -> [[String: DimensionValue]] {
        return try await Self.records("purchases", of: provider)
    }

    static func entitlements(of provider: CustomerInfoDimensionProvider) async throws -> [[String: DimensionValue]] {
        return try await Self.records("entitlements", of: provider)
    }

    static func purchase(
        withProductIdentifier productIdentifier: String,
        of provider: CustomerInfoDimensionProvider
    ) async throws -> [String: DimensionValue] {
        return try #require(
            try await Self.purchases(of: provider)
                .first { $0["productIdentifier"] == .string(productIdentifier) }
        )
    }

    static func records(
        _ name: String,
        of provider: CustomerInfoDimensionProvider
    ) async throws -> [[String: DimensionValue]] {
        let dimensions = try await provider.dimensions(in: Self.context)
        guard case .objectList(let records) = dimensions[name] else {
            Issue.record("'\(name)' is not a collection of records: \(String(describing: dimensions[name]))")
            return []
        }

        return records
    }

}

private actor CountingCustomerInfoReader {

    private let customerInfo: CustomerInfo
    private(set) var readCount = 0

    init(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo
    }

    func read() -> CustomerInfo {
        self.readCount += 1
        return self.customerInfo
    }

}

#endif
#endif
