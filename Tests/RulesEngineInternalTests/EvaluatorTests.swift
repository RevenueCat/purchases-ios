//
//  EvaluatorTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class EvaluatorTests: XCTestCase {

    // MARK: - Error paths
    //
    // Kept as a Swift test (not migrated to a JSON fixture): this asserts
    // that parsing a malformed JSON *string* throws. A fixture's `predicate`
    // must itself be valid JSON in the file, so the malformed input can only
    // be exercised through the test-only `Value.fromJSONString` helper.

    func testMalformedJSONSurfacesParseError() {
        // Parse errors now surface from the test-only JSON helper (production
        // callers parse on the native side and never hand `evaluate` a
        // malformed tree). The error case is still `RuleError.parse`.
        XCTAssertThrowsError(try Value.fromJSONString("{not json")) { error in
            guard case RuleError.parse = error else {
                return XCTFail("expected RuleError.parse, got \(error)")
            }
        }
    }
}
