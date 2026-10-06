//
//  SubscriberDimensionsTests.swift
//  RevenueCatTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class SubscriberDimensionsTests: TestCase {

    func testDecodesTheBackendDefaultItem() throws {
        let dimensions = try Self.dimensions(#"""
        {
            "dimensions": {
                "country": "ES",
                "subscription_status": null,
                "total_renewals": 0,
                "total_spent": 12.5,
                "first_purchase_at": 1790858464004,
                "latest_auto_renew_intent": false
            },
            "as_of": 1790858464258
        }
        """#)

        expect(dimensions.values) == [
            "country": .string("ES"),
            "subscription_status": .null,
            "total_renewals": .int(0),
            "total_spent": .double(12.5),
            "first_purchase_at": .int(1790858464004),
            "latest_auto_renew_intent": .bool(false)
        ]
        expect(dimensions.asOf) == 1790858464258
    }

    func testKeepsAnEmptyDimensionsObjectWithItsTimestamp() throws {
        expect(try Self.dimensions(#"{"dimensions": {}, "as_of": 1}"#)) == SubscriberDimensions(
            values: [:],
            asOf: 1
        )
    }

    func testDropsValuesTheRulesEngineCannotRead() throws {
        let dimensions = try Self.dimensions(#"{"dimensions": {"tags": [1, 2], "country": "ES"}, "as_of": 1}"#)

        expect(dimensions.values) == ["country": .string("ES")]
    }

    func testRejectsAnItemWithoutADimensionsObject() throws {
        expect { try Self.dimensions(#"{"as_of": 1}"#) }.to(throwError())
        expect { try Self.dimensions(#"{"dimensions": null, "as_of": 1}"#) }.to(throwError())
        expect { try Self.dimensions(#"{"dimensions": "ES", "as_of": 1}"#) }.to(throwError())
        expect { try Self.dimensions(#"{"dimensions": [], "as_of": 1}"#) }.to(throwError())
    }

    func testRejectsAnItemWithoutAnEpochMillisecondsTimestamp() throws {
        expect { try Self.dimensions(#"{"dimensions": {}}"#) }.to(throwError())
        expect { try Self.dimensions(#"{"dimensions": {}, "as_of": null}"#) }.to(throwError())
        expect { try Self.dimensions(#"{"dimensions": {}, "as_of": "yesterday"}"#) }.to(throwError())
        expect { try Self.dimensions(#"{"dimensions": {}, "as_of": -1}"#) }.to(throwError())
    }

    private static func dimensions(_ json: String) throws -> SubscriberDimensions {
        return try JSONDecoder.default.decode(SubscriberDimensions.self, from: Data(json.utf8))
    }

}
