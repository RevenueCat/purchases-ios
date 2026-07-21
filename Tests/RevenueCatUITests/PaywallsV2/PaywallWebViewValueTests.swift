//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class PaywallWebViewValueTests: TestCase {

    func testFactoryAccessorsAndCodableRoundTrip() throws {
        let value: PaywallWebViewValue = .object([
            "string": .string("value"),
            "number": .number(1.25),
            "bool": .bool(true),
            "array": .array([.null, .string("x")]),
            "object": .object(["nested": .bool(false)]),
            "null": .null
        ])

        let decoded = try JSONDecoder().decode(
            PaywallWebViewValue.self,
            from: try JSONEncoder().encode(value)
        )

        XCTAssertEqual(decoded, value)
        XCTAssertEqual(decoded.objectValue?["string"]?.stringValue, "value")
        XCTAssertEqual(decoded.objectValue?["number"]?.numberValue, 1.25)
        XCTAssertEqual(decoded.objectValue?["bool"]?.boolValue, true)
        XCTAssertTrue(decoded.objectValue?["null"]?.isNull == true)

        let array = try XCTUnwrap(decoded.objectValue?["array"]?.arrayValue)
        XCTAssertEqual(array.count, 2)
        XCTAssertTrue(array.first?.isNull == true)
        XCTAssertEqual(array.last?.stringValue, "x")

        XCTAssertEqual(decoded.objectValue?["object"]?.objectValue?["nested"]?.boolValue, false)
    }

    func testTopLevelScalarsAndEmptyContainersRoundTrip() throws {
        let values: [PaywallWebViewValue] = [
            .string("hello"),
            .number(1.25),
            .bool(true),
            .bool(false),
            .null,
            .array([]),
            .object([:])
        ]

        for value in values {
            let decoded = try JSONDecoder().decode(
                PaywallWebViewValue.self,
                from: try JSONEncoder().encode(value)
            )
            XCTAssertEqual(decoded, value)
        }

        XCTAssertEqual(PaywallWebViewValue.array([]).arrayValue, [])
        XCTAssertEqual(PaywallWebViewValue.object([:]).objectValue, [:])
    }

    func testNumberBoolDisambiguation() throws {
        let decoded = try JSONDecoder().decode(
            PaywallWebViewValue.self,
            from: Data(#"{"bool":true,"number":1}"#.utf8)
        )

        XCTAssertEqual(decoded.objectValue?["bool"]?.boolValue, true)
        XCTAssertNil(decoded.objectValue?["bool"]?.numberValue)
        XCTAssertEqual(decoded.objectValue?["number"]?.numberValue, 1)
    }

    func testNonFiniteNumbersNormalizeToNullAndEncode() throws {
        XCTAssertTrue(PaywallWebViewValue.number(.nan).isNull)
        XCTAssertTrue(PaywallWebViewValue.number(.infinity).isNull)
        XCTAssertTrue(PaywallWebViewValue.number(-.infinity).isNull)
        XCTAssertNil(PaywallWebViewValue.number(.nan).numberValue)

        let value: PaywallWebViewValue = .object(["bad": .number(.nan)])
        XCTAssertNoThrow(try JSONEncoder().encode(value))
        XCTAssertEqual(PaywallWebViewValue.number(-0.0), .number(0.0))
    }

}

#endif
