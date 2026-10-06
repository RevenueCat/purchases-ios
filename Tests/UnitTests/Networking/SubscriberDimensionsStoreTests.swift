//
//  SubscriberDimensionsStoreTests.swift
//  RevenueCatTests
//
//  Created by Rick van der Linden on 10/2/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

final class SubscriberDimensionsStoreTests: TestCase {

    private var deviceCache: MockDeviceCache!
    private var store: SubscriberDimensionsStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.deviceCache = MockDeviceCache()
        self.store = SubscriberDimensionsStore(deviceCache: self.deviceCache)
    }

    func testStoresTimestampedDimensionsFromReceiptResponse() throws {
        let customerInfo = try Self.customerInfo([
            "dimensions": ["country": "NL", "active": true],
            "as_of": 1_000
        ])

        self.store.store(customerInfo, appUserID: "user")

        expect(self.store.dimensions(appUserID: "user")) == .init(
            values: ["country": .string("NL"), "active": .bool(true)],
            asOf: 1_000
        )
    }

    func testResponseWithoutDimensionsKeepsPreviousCopy() throws {
        self.store.store(
            try Self.customerInfo(["dimensions": ["country": "NL"], "as_of": 1_000]),
            appUserID: "user"
        )

        self.store.store(try Self.customerInfo([:]), appUserID: "user")

        expect(self.store.dimensions(appUserID: "user")?.values) == ["country": .string("NL")]
    }

    func testIncompleteDimensionsKeepPreviousCopy() throws {
        self.store.store(
            try Self.customerInfo(["dimensions": ["country": "NL"], "as_of": 1_000]),
            appUserID: "user"
        )

        self.store.store(
            try Self.customerInfo(["dimensions": ["country": "US"]]),
            appUserID: "user"
        )

        expect(self.store.dimensions(appUserID: "user")?.values) == ["country": .string("NL")]
    }

    func testDiscardOnlyRemovesTheSupersededCopy() throws {
        self.store.store(
            try Self.customerInfo(["dimensions": ["country": "NL"], "as_of": 2_000]),
            appUserID: "user"
        )

        self.store.discard(appUserID: "user", ifNotNewerThan: 1_000)
        expect(self.store.dimensions(appUserID: "user")).toNot(beNil())

        self.store.discard(appUserID: "user", ifNotNewerThan: 2_000)
        expect(self.store.dimensions(appUserID: "user")).to(beNil())
    }

    private static func customerInfo(_ fields: [String: Any]) throws -> CustomerInfo {
        return try CustomerInfo(data: fields.merging([
            "request_date": "2026-10-02T10:00:00Z",
            "subscriber": [
                "original_app_user_id": "user",
                "first_seen": "2026-10-02T10:00:00Z",
                "subscriptions": [String: Any](),
                "other_purchases": [String: Any](),
                "original_application_version": NSNull()
            ] as [String: Any]
        ]) { value, _ in value })
    }

}
