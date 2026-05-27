//
//  StringArrayOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

// swiftlint:disable type_body_length
final class StringArrayOperatorsTests: XCTestCase {

    // MARK: - in

    func testInSubstringMatchForStringHaystack() throws {
        let out = try StringArrayOperators.opIn(
            args: arr(.string("bar"), .string("foobar")),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testInSubstringNoMatchForStringHaystack() throws {
        let out = try StringArrayOperators.opIn(
            args: arr(.string("baz"), .string("foobar")),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testInArrayMembershipStrictTypes() throws {
        let out = try StringArrayOperators.opIn(
            args: arr(
                .string("US"),
                arr(.string("US"), .string("CA"), .string("MX"))
            ),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testInArrayMembershipUsesLooseEq() throws {
        // 5 vs "5" — looseEq says equal. Documented deviation from JS
        // reference's strict `===` membership.
        let out = try StringArrayOperators.opIn(
            args: arr(.int(5), arr(.string("5"), .string("6"))),
            vars: .null
        )
        XCTAssertEqual(out, .bool(true))
    }

    func testInNonStringNeedleInStringHaystackIsFalse() throws {
        // We only support substring search when both sides are strings.
        let out = try StringArrayOperators.opIn(
            args: arr(.int(5), .string("12345")),
            vars: .null
        )
        XCTAssertEqual(out, .bool(false))
    }

    func testInUnsupportedHaystackTypeIsFalse() throws {
        // Null, numbers, bools, objects all return false (no `indexOf`
        // in JS).
        let unsupported: [Value] = [.null, .int(123), .bool(true), .object([:])]
        for haystack in unsupported {
            let out = try StringArrayOperators.opIn(
                args: arr(.string("x"), haystack),
                vars: .null
            )
            XCTAssertEqual(out, .bool(false))
        }
    }

    func testInArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try StringArrayOperators.opIn(
                args: arr(.string("only-one")),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    // MARK: - cat

    func testCatConcatenatesStrings() throws {
        let out = try StringArrayOperators.opCat(
            args: arr(.string("I love "), .string("pie")),
            vars: .null
        )
        XCTAssertEqual(out, .string("I love pie"))
    }

    func testCatStringifiesMixedOperandTypes() throws {
        let out = try StringArrayOperators.opCat(
            args: arr(
                .string("count="),
                .int(7),
                .string(", active="),
                .bool(true)
            ),
            vars: .null
        )
        XCTAssertEqual(out, .string("count=7, active=true"))
    }

    func testCatZeroArgsReturnsEmptyString() throws {
        let out = try StringArrayOperators.opCat(
            args: arr(),
            vars: .null
        )
        XCTAssertEqual(out, .string(""))
    }

    func testCatSingletonShorthandIsSupported() throws {
        // `{"cat": "hello"}` ≡ `{"cat": ["hello"]}` per `argsAsList`.
        let out = try StringArrayOperators.opCat(
            args: .string("hello"),
            vars: .null
        )
        XCTAssertEqual(out, .string("hello"))
    }

    func testCatStringifiesNullAsStringNull() throws {
        let out = try StringArrayOperators.opCat(
            args: arr(.string("x="), .null),
            vars: .null
        )
        XCTAssertEqual(out, .string("x=null"))
    }

    func testCatStringifiesArrayWithCommaJoin() throws {
        // Mirrors JS `Array.prototype.toString` — `[1,2,3].toString()`
        // is "1,2,3".
        let out = try StringArrayOperators.opCat(
            args: arr(
                .string("vals="),
                arr(.int(1), .int(2))
            ),
            vars: .null
        )
        XCTAssertEqual(out, .string("vals=1,2"))
    }

    /// `Array.prototype.join` (which `String([...])` uses) renders
    /// `null` and `undefined` elements as empty strings:
    /// `String([1, null, 2])` is `"1,,2"` in JS, not `"1,null,2"`.
    func testCatStringifiesNullElementsInArrayAsEmpty() throws {
        let out = try StringArrayOperators.opCat(
            args: arr(arr(.int(1), .null, .int(2))),
            vars: .null
        )
        XCTAssertEqual(out, .string("1,,2"))
    }

    // MARK: - substr

    func testSubstrTwoArgsExtractsToEnd() throws {
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("hello"), .int(1)),
            vars: .null
        )
        XCTAssertEqual(out, .string("ello"))
    }

    func testSubstrThreeArgsExtractsFixedLength() throws {
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("hello"), .int(1), .int(3)),
            vars: .null
        )
        XCTAssertEqual(out, .string("ell"))
    }

    func testSubstrNegativeStartCountsFromEnd() throws {
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("hello"), .int(-2)),
            vars: .null
        )
        XCTAssertEqual(out, .string("lo"))
    }

    func testSubstrNegativeLengthDropsFromRight() throws {
        // {"substr": ["hello", 1, -2]}:
        //   step 1: "hello".substr(1) = "ello"
        //   step 2: "ello".substr(0, len("ello") + (-2)) = "el"
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("hello"), .int(1), .int(-2)),
            vars: .null
        )
        XCTAssertEqual(out, .string("el"))
    }

    func testSubstrStartPastEndReturnsEmpty() throws {
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("abc"), .int(10)),
            vars: .null
        )
        XCTAssertEqual(out, .string(""))
    }

    func testSubstrNegativeStartClampedToZero() throws {
        // {"substr": ["abc", -10]} — negative beyond length clamps to
        // start of string, returning the full string.
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("abc"), .int(-10)),
            vars: .null
        )
        XCTAssertEqual(out, .string("abc"))
    }

    func testSubstrLengthExceedingRemainingClamps() throws {
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("abc"), .int(0), .int(100)),
            vars: .null
        )
        XCTAssertEqual(out, .string("abc"))
    }

    func testSubstrSlicesByCodepointNotByte() throws {
        // Multibyte UTF-8 — "café" is 4 user-perceived characters but
        // 5 bytes. Slicing from index 1 should give "afé".
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("café"), .int(1)),
            vars: .null
        )
        XCTAssertEqual(out, .string("afé"))
    }

    func testSubstrStringifiesNonStringSource() throws {
        // Source is coerced via `stringify` — `.int(12345)` becomes
        // "12345".
        let out = try StringArrayOperators.opSubstr(
            args: arr(.int(12345), .int(1), .int(3)),
            vars: .null
        )
        XCTAssertEqual(out, .string("234"))
    }

    func testSubstrArityMismatchIsTypeError() {
        XCTAssertThrowsError(
            try StringArrayOperators.opSubstr(
                args: arr(.string("hello")),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
        XCTAssertThrowsError(
            try StringArrayOperators.opSubstr(
                args: arr(.string("hello"), .int(0), .int(0), .int(0)),
                vars: .null
            )
        ) { error in
            guard case RuleError.typeMismatch = error else {
                return XCTFail("expected typeMismatch, got \(error)")
            }
        }
    }

    func testSubstrWithNanStartTreatsItAsZero() throws {
        // `Int(Double.nan)` traps, so an unguarded coercion would crash for
        // any expression that produces NaN (`.float(.nan)` directly, an
        // arithmetic-on-non-numeric chain, etc.). Spec semantics: NaN → 0.
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("abcd"), .float(.nan)),
            vars: .null
        )
        XCTAssertEqual(out, .string("abcd"))
    }

    func testSubstrWithInfiniteStartClampsToTotal() throws {
        // `+Infinity` start → empty substring (start is at/past the end).
        let outPositive = try StringArrayOperators.opSubstr(
            args: arr(.string("abcd"), .float(.infinity)),
            vars: .null
        )
        XCTAssertEqual(outPositive, .string(""))

        // `-Infinity` start → clamp to 0, return the whole string.
        let outNegative = try StringArrayOperators.opSubstr(
            args: arr(.string("abcd"), .float(-.infinity)),
            vars: .null
        )
        XCTAssertEqual(outNegative, .string("abcd"))
    }

    func testSubstrWithOversizedStartClampsToTotal() throws {
        // Finite Double well beyond `Int.max` would trap the Int init;
        // clamp to total length and return empty.
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("abcd"), .float(1.0e20)),
            vars: .null
        )
        XCTAssertEqual(out, .string(""))
    }

    func testSubstrWithNanLengthTreatsItAsZero() throws {
        // NaN length → 0 → empty result, mirroring JS `ToInteger`.
        let out = try StringArrayOperators.opSubstr(
            args: arr(.string("abcd"), .int(0), .float(.nan)),
            vars: .null
        )
        XCTAssertEqual(out, .string(""))
    }

    func testSubstrWithInfiniteLengthReturnsRemaining() throws {
        // `+Infinity` length → clamp to remaining; `-Infinity` → clamp to 0
        // → empty.
        let outPositive = try StringArrayOperators.opSubstr(
            args: arr(.string("abcd"), .int(1), .float(.infinity)),
            vars: .null
        )
        XCTAssertEqual(outPositive, .string("bcd"))

        let outNegative = try StringArrayOperators.opSubstr(
            args: arr(.string("abcd"), .int(1), .float(-.infinity)),
            vars: .null
        )
        XCTAssertEqual(outNegative, .string(""))
    }

    // MARK: - merge

    func testMergeFlattensArraysOneLevel() throws {
        let out = try StringArrayOperators.opMerge(
            args: arr(
                arr(.int(1), .int(2)),
                arr(.int(3), .int(4))
            ),
            vars: .null
        )
        XCTAssertEqual(out, arr(.int(1), .int(2), .int(3), .int(4)))
    }

    func testMergePromotesScalarsToSingletons() throws {
        // {"merge": [1, 2, [3, 4]]} → [1, 2, 3, 4]
        let out = try StringArrayOperators.opMerge(
            args: arr(
                .int(1),
                .int(2),
                arr(.int(3), .int(4))
            ),
            vars: .null
        )
        XCTAssertEqual(out, arr(.int(1), .int(2), .int(3), .int(4)))
    }

    func testMergeZeroArgsReturnsEmptyArray() throws {
        let out = try StringArrayOperators.opMerge(
            args: arr(),
            vars: .null
        )
        XCTAssertEqual(out, arr())
    }

    func testMergeDoesNotRecurseOnNestedArrays() throws {
        // Only one level of flattening — inner arrays remain.
        let out = try StringArrayOperators.opMerge(
            args: arr(arr(arr(.int(1)), .int(2))),
            vars: .null
        )
        XCTAssertEqual(out, arr(arr(.int(1)), .int(2)))
    }

    // MARK: - Helpers

    private func arr(_ items: Value...) -> Value {
        .array(items)
    }
}
