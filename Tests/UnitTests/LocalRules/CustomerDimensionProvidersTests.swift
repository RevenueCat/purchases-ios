//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerDimensionProvidersTests.swift
//
//  Created by Facundo Menzella on 25/8/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Server snapshot dimension provider")
struct ServerSnapshotDimensionProviderTests {

    @Test
    func forwardsWhateverTheBackendWorkedOutWithoutReadingIt() async throws {
        let dimensions = try await Self.provider(dimensions: [
            "somethingThisSDKNeverHeardOf": "a value",
            "purchaseCount": 3,
            "isBigSpender": true,
            "churnRisk": 0.25,
            "purchases": [["productIdentifier": "premium"], ["productIdentifier": "coins"]],
            "lifetime": ["value": 42]
        ]).dimensions(in: Self.context)

        #expect(dimensions["somethingThisSDKNeverHeardOf"] == .string("a value"))
        #expect(dimensions["purchaseCount"] == .int(3))
        #expect(dimensions["isBigSpender"] == .bool(true))
        #expect(dimensions["churnRisk"] == .double(0.25))
        #expect(dimensions["purchases"] == .objectList([
            ["productIdentifier": .string("premium")],
            ["productIdentifier": .string("coins")]
        ]))
        #expect(dimensions["lifetime"] == .object(["value": .int(42)]))
    }

    @Test
    func leavesOutWhatJSONLogicCannotRead() async throws {
        let dimensions = try await Self.provider(dimensions: [
            "nothing": NSNull(),
            "scalars": [1, 2, 3],
            "mixed": [["a": 1], "b"],
            "kept": "yes"
        ]).dimensions(in: Self.context)

        #expect(Set(dimensions.keys) == ["kept"])
    }

    @Test
    func survivesTheEncodeTheCustomerInfoCachePerforms() async throws {
        // The cache stores an encoded customer info and reads it back, and a field the SDK does
        // not model is dropped on the way out. These have to still be there afterwards.
        let original = try CustomerInfoFixture.make(dimensions: ["churnRisk": 0.25, "tier": "gold"])
        let encoded = try JSONEncoder.default.encode(original)
        let restored = try JSONDecoder.default.decode(CustomerInfo.self, from: encoded)

        let dimensions = try await ServerSnapshotDimensionProvider(
            customerInfoProvider: StubCustomerInfoSource { _ in restored }
        ).dimensions(in: Self.context)

        #expect(dimensions["churnRisk"] == .double(0.25))
        #expect(dimensions["tier"] == .string("gold"))
    }

    @Test
    func contributesNothingWhenTheBackendSentNoDimensions() async throws {
        let dimensions = try await Self.provider(dimensions: nil).dimensions(in: Self.context)

        #expect(dimensions.isEmpty)
    }

    @Test
    func contributesNothingWhenTheCustomerInfoCannotBeRead() async throws {
        let provider = ServerSnapshotDimensionProvider(
            customerInfoProvider: StubCustomerInfoSource { _ in throw ErrorUtils.offlineConnectionError() }
        )

        #expect(try await provider.dimensions(in: Self.context).isEmpty)
    }

    static func provider(dimensions: [String: Any]?) -> ServerSnapshotDimensionProvider {
        // swiftlint:disable:next force_try
        let customerInfo = try! CustomerInfoFixture.make(dimensions: dimensions)
        return ServerSnapshotDimensionProvider(customerInfoProvider: StubCustomerInfoSource { _ in customerInfo })
    }

}

@Suite("Active entitlements dimension provider")
struct ActiveEntitlementsDimensionProviderTests {

    @Test
    func describesEachActiveEntitlementByIdentifier() async throws {
        let dimensions = try await Self.provider().dimensions(in: Self.context)

        #expect(dimensions["appUserId"] == .string("current_user"))
        #expect(dimensions["activeEntitlements"] == .object([
            "premium": .object([
                "productIdentifier": .string("premium"),
                "expiresAt": .date(CustomerInfoFixture.distantExpiry)
            ])
        ]))
    }

    @Test
    func leavesOutAnEntitlementThatHasLapsed() async throws {
        let dimensions = try await Self.provider(expiresDate: CustomerInfoFixture.lapsedExpiry)
            .dimensions(in: Self.context)

        #expect(dimensions["activeEntitlements"] == .object([:]))
    }

    @Test
    func readsTheCustomerTheSnapshotIsFor() async throws {
        let requested = Atomic<String?>(nil)
        let provider = ActiveEntitlementsDimensionProvider(
            customerInfoProvider: StubCustomerInfoSource { appUserID in
                requested.value = appUserID
                return try CustomerInfoFixture.make()
            }
        )

        let dimensions = try await provider.dimensions(
            in: DimensionContext(date: Date(), appUserID: "user_a")
        )

        #expect(requested.value == "user_a")
        #expect(dimensions["appUserId"] == .string("user_a"))
    }

    @Test
    func omitsTheEntitlementsItCouldNotReadRatherThanReportingNone() async throws {
        let provider = ActiveEntitlementsDimensionProvider(
            customerInfoProvider: StubCustomerInfoSource { _ in throw ErrorUtils.offlineConnectionError() }
        )

        let dimensions = try await provider.dimensions(in: Self.context)

        // A customer whose entitlements could not be read is not a customer holding none: the
        // dimension is absent, so a rule about it fails to resolve rather than matching.
        #expect(dimensions["activeEntitlements"] == nil)
        #expect(dimensions["appUserId"] == .string("current_user"))
    }

    @Test
    func cancellationPropagates() async throws {
        let provider = ActiveEntitlementsDimensionProvider(
            customerInfoProvider: StubCustomerInfoSource { _ in throw CancellationError() }
        )

        await #expect(throws: CancellationError.self) {
            try await provider.dimensions(in: Self.context)
        }
    }

    @Test
    func makesTheEntitlementsReadableByARule() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [Self.provider()],
            currentUserProvider: StubCurrentUserProvider("current_user")
        ).snapshot()

        let holdsPremium = #"{"!!": {"var": "clientSnapshot.activeEntitlements.premium"}}"#
        let doesNotHoldPro = #"{"!!": {"var": "clientSnapshot.activeEntitlements.pro"}}"#

        #expect(RulesEngine.evaluate(predicate: holdsPremium, variables: snapshot.values) == .success(true))
        #expect(
            RulesEngine.evaluate(predicate: doesNotHoldPro, variables: snapshot.values)
            == .failure(.unresolvedVariable(path: "clientSnapshot.activeEntitlements.pro"))
        )
    }

    static func provider(
        expiresDate: Date = CustomerInfoFixture.distantExpiry
    ) -> ActiveEntitlementsDimensionProvider {
        // swiftlint:disable:next force_try
        let customerInfo = try! CustomerInfoFixture.make(expiresDate: expiresDate)
        return ActiveEntitlementsDimensionProvider(customerInfoProvider: StubCustomerInfoSource { _ in customerInfo })
    }

}

@Suite("Customer dimensions in one snapshot")
struct CustomerDimensionsSnapshotTests {

    @Test
    func bothSnapshotsResolveSideBySide() async throws {
        // The two customer providers are registered together in `Purchases`, and the resolver
        // rejects two providers claiming the same path, so they have to agree on who owns what.
        let customerInfo = try CustomerInfoFixture.make(dimensions: ["churnRisk": 0.25])
        let currentUser = StubCurrentUserProvider("current_user")
        let source = StubCustomerInfoSource { _ in customerInfo }

        let snapshot = try await DimensionResolver(
            dimensionProviders: [
                ServerSnapshotDimensionProvider(customerInfoProvider: source),
                ActiveEntitlementsDimensionProvider(customerInfoProvider: source)
            ],
            currentUserProvider: currentUser
        ).snapshot()

        let readsBoth = """
        {"and": [{"==": [{"var": "serverSnapshot.churnRisk"}, 0.25]}, \
        {"!!": {"var": "clientSnapshot.activeEntitlements.premium"}}]}
        """

        #expect(RulesEngine.evaluate(predicate: readsBoth, variables: snapshot.values) == .success(true))
    }

    @Test
    func describesOneCustomerWhenTheUserChangesMidSnapshot() async throws {
        // Each provider reads the current user for itself and the resolver awaits them in turn, so
        // a login landing between the two reads must not put two customers in one snapshot.
        let currentUser = MutableCurrentUserProvider("user_a")
        let source = StubCustomerInfoSource { appUserID in
            currentUser.currentAppUserID = "user_b"
            return try CustomerInfoFixture.make(dimensions: ["appUserId": appUserID])
        }

        let snapshot = try await DimensionResolver(
            dimensionProviders: [
                ServerSnapshotDimensionProvider(customerInfoProvider: source),
                ActiveEntitlementsDimensionProvider(customerInfoProvider: source)
            ],
            currentUserProvider: currentUser
        ).snapshot()

        let describesOneCustomer = """
        {"==": [{"var": "serverSnapshot.appUserId"}, {"var": "clientSnapshot.appUserId"}]}
        """

        #expect(currentUser.currentAppUserID == "user_b")
        #expect(
            RulesEngine.evaluate(predicate: describesOneCustomer, variables: snapshot.values) == .success(true)
        )
    }

}

// MARK: - Helpers

extension ServerSnapshotDimensionProviderTests {
    static let context = DimensionContext(date: Date(), appUserID: "current_user")
}

extension ActiveEntitlementsDimensionProviderTests {
    static let context = DimensionContext(date: Date(), appUserID: "current_user")
}

enum CustomerInfoFixture {

    // swiftlint:disable:next force_unwrapping
    static let requestDate = ISO8601DateFormatter().date(from: "2026-06-15T12:00:00Z")!
    // swiftlint:disable:next force_unwrapping
    static let distantExpiry = ISO8601DateFormatter().date(from: "2100-01-01T00:00:00Z")!
    // swiftlint:disable:next force_unwrapping
    static let lapsedExpiry = ISO8601DateFormatter().date(from: "2020-01-01T00:00:00Z")!

    static func make(
        expiresDate: Date = CustomerInfoFixture.distantExpiry,
        dimensions: [String: Any]? = nil
    ) throws -> CustomerInfo {
        let formatter = ISO8601DateFormatter()
        var subscriber: [String: Any] = [
            "original_app_user_id": "original_user",
            "first_seen": formatter.string(from: Self.requestDate),
            "original_application_version": "1.0",
            "subscriptions": [
                "premium": [
                    "period_type": "normal",
                    "purchase_date": formatter.string(from: Self.requestDate),
                    "expires_date": formatter.string(from: expiresDate),
                    "store": "app_store",
                    "is_sandbox": false
                ] as [String: Any]
            ],
            "non_subscriptions": [:] as [String: Any],
            "entitlements": [
                "premium": [
                    "product_identifier": "premium",
                    "purchase_date": formatter.string(from: Self.requestDate),
                    "expires_date": formatter.string(from: expiresDate)
                ] as [String: Any]
            ]
        ]
        if let dimensions {
            subscriber["dimensions"] = dimensions
        }

        return try CustomerInfo(data: [
            "request_date": formatter.string(from: Self.requestDate),
            "subscriber": subscriber
        ])
    }

}

struct StubCustomerInfoSource: CustomerInfoDimensionSource {

    let read: @Sendable (String) async throws -> CustomerInfo

    init(_ read: @escaping @Sendable (String) async throws -> CustomerInfo) {
        self.read = read
    }

    func customerInfo(appUserID: String) async throws -> CustomerInfo {
        return try await self.read(appUserID)
    }

}

final class MutableCurrentUserProvider: CurrentUserProvider, @unchecked Sendable {

    private let lock = NSLock()
    private var appUserID: String

    var currentAppUserID: String {
        get { self.lock.withLock { self.appUserID } }
        set { self.lock.withLock { self.appUserID = newValue } }
    }

    var currentUserIsAnonymous: Bool { false }

    init(_ appUserID: String) {
        self.appUserID = appUserID
    }

}

final class StubCurrentUserProvider: CurrentUserProvider {

    let currentAppUserID: String
    var currentUserIsAnonymous: Bool { false }

    init(_ currentAppUserID: String) {
        self.currentAppUserID = currentAppUserID
    }

}

#endif
#endif
