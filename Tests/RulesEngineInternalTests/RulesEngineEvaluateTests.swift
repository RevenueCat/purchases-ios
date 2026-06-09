//
//  RulesEngineEvaluateTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngineInternal

final class RulesEngineEvaluateTests: XCTestCase {

    func testEvaluatesTruthyPredicate() {
        let result = RulesEngine.evaluate(predicate: "true", variables: [:])
        XCTAssertEqual(try result.get(), true)
    }

    func testEvaluatesFalsyPredicate() {
        let result = RulesEngine.evaluate(predicate: "false", variables: [:])
        XCTAssertEqual(try result.get(), false)
    }

    func testEvaluatesPredicateAgainstVariables() {
        let result = RulesEngine.evaluate(
            predicate: #"{"==":[{"var":"x"},1]}"#,
            variables: ["x": .int(1)]
        )
        XCTAssertEqual(try result.get(), true)
    }

    func testMalformedJSONReturnsParseFailure() {
        let result = RulesEngine.evaluate(predicate: "{not json", variables: [:])
        guard case .failure(.parse) = result else {
            return XCTFail("expected .failure(.parse), got \(result)")
        }
    }

    func testUnsupportedOperatorReturnsFailure() {
        let result = RulesEngine.evaluate(predicate: #"{"nope":[]}"#, variables: [:])
        guard case .failure(.unsupportedOperator) = result else {
            return XCTFail("expected .failure(.unsupportedOperator), got \(result)")
        }
    }
}
