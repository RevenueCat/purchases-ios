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
        ]).dimensions(at: Date())

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
        ]).dimensions(at: Date())

        #expect(Set(dimensions.keys) == ["kept"])
    }

    @Test
    func contributesNothingWhenTheBackendSentNoDimensions() async throws {
        let dimensions = try await Self.provider(dimensions: nil).dimensions(at: Date())

        #expect(dimensions.isEmpty)
    }

    @Test
    func contributesNothingWhenTheCustomerInfoCannotBeRead() async throws {
        let provider = ServerSnapshotDimensionProvider(
            currentUserProvider: StubCurrentUserProvider("current_user"),
            customerInfoProvider: StubCustomerInfoSource { _ in throw ErrorUtils.offlineConnectionError() }
        )

        #expect(try await provider.dimensions(at: Date()).isEmpty)
    }

    static func provider(dimensions: [String: Any]?) -> ServerSnapshotDimensionProvider {
        // swiftlint:disable:next force_try
        let customerInfo = try! CustomerInfoFixture.make(dimensions: dimensions)
        return ServerSnapshotDimensionProvider(
            currentUserProvider: StubCurrentUserProvider("current_user"),
            customerInfoProvider: StubCustomerInfoSource { _ in customerInfo }
        )
    }

}

@Suite("Active entitlements dimension provider")
struct ActiveEntitlementsDimensionProviderTests {

    @Test
    func describesEachActiveEntitlementByIdentifier() async throws {
        let dimensions = try await Self.provider().dimensions(at: Date())

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
            .dimensions(at: Date())

        #expect(dimensions["activeEntitlements"] == .object([:]))
    }

    @Test
    func readsTheCustomerTheRequestWasMadeFor() async throws {
        let requested = Atomic<String?>(nil)
        let provider = ActiveEntitlementsDimensionProvider(
            currentUserProvider: StubCurrentUserProvider("user_a"),
            customerInfoProvider: StubCustomerInfoSource { appUserID in
                requested.value = appUserID
                return try CustomerInfoFixture.make()
            }
        )

        let dimensions = try await provider.dimensions(at: Date())

        #expect(requested.value == "user_a")
        #expect(dimensions["appUserId"] == .string("user_a"))
    }

    @Test
    func omitsTheEntitlementsItCouldNotReadRatherThanReportingNone() async throws {
        let provider = ActiveEntitlementsDimensionProvider(
            currentUserProvider: StubCurrentUserProvider("current_user"),
            customerInfoProvider: StubCustomerInfoSource { _ in throw ErrorUtils.offlineConnectionError() }
        )

        let dimensions = try await provider.dimensions(at: Date())

        // A customer whose entitlements could not be read is not a customer holding none: the
        // dimension is absent, so a rule about it fails to resolve rather than matching.
        #expect(dimensions["activeEntitlements"] == nil)
        #expect(dimensions["appUserId"] == .string("current_user"))
    }

    @Test
    func cancellationPropagates() async throws {
        let provider = ActiveEntitlementsDimensionProvider(
            currentUserProvider: StubCurrentUserProvider("current_user"),
            customerInfoProvider: StubCustomerInfoSource { _ in throw CancellationError() }
        )

        await #expect(throws: CancellationError.self) {
            try await provider.dimensions(at: Date())
        }
    }

    @Test
    func makesTheEntitlementsReadableByARule() async throws {
        let snapshot = try await DimensionResolver(dimensionProviders: [Self.provider()]).snapshot()

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
        return ActiveEntitlementsDimensionProvider(
            currentUserProvider: StubCurrentUserProvider("current_user"),
            customerInfoProvider: StubCustomerInfoSource { _ in customerInfo }
        )
    }

}

// MARK: - Helpers

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

final class StubCurrentUserProvider: CurrentUserProvider {

    let currentAppUserID: String
    var currentUserIsAnonymous: Bool { false }

    init(_ currentAppUserID: String) {
        self.currentAppUserID = currentAppUserID
    }

}

#endif
#endif
