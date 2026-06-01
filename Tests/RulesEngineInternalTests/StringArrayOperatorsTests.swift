//
//  StringArrayOperatorsTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class StringArrayOperatorsTests: XCTestCase {

    // MARK: - merge

    /// Kept as a Swift test (not migrated to a JSON fixture): `merge`
    /// returns an array, and this engine's loose `==` string-coerces
    /// `[[1], 2]` and `[1, 2]` to the same `"1,2"`, so no predicate can
    /// verify that nested arrays are NOT recursively flattened. Only a
    /// structural `Value` comparison can.
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
