//
//  RulesEngineEvaluateTests.swift
//
//  Created by Antonio Pallares.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Testing

@testable import RulesEngineInternal

@Suite("RulesEngine.evaluate")
struct RulesEngineEvaluateTests {

    @Test
    func evaluatesTruthyPredicate() throws {
        let result = RulesEngine.evaluate(predicate: "true", variables: [:])
        #expect(try result.get() == true)
    }

    @Test
    func evaluatesFalsyPredicate() throws {
        let result = RulesEngine.evaluate(predicate: "false", variables: [:])
        #expect(try result.get() == false)
    }

    @Test
    func evaluatesPredicateAgainstVariables() throws {
        let result = RulesEngine.evaluate(
            predicate: #"{"==":[{"var":"x"},1]}"#,
            variables: ["x": .int(1)]
        )
        #expect(try result.get() == true)
    }

    @Test
    func malformedJSONReturnsParseFailure() {
        let result = RulesEngine.evaluate(predicate: "{not json", variables: [:])
        guard case .failure(.parse) = result else {
            Issue.record("expected .failure(.parse), got \(result)")
            return
        }
    }

    @Test
    func unsupportedOperatorReturnsFailure() {
        let result = RulesEngine.evaluate(predicate: #"{"nope":[]}"#, variables: [:])
        guard case .failure(.unsupportedOperator) = result else {
            Issue.record("expected .failure(.unsupportedOperator), got \(result)")
            return
        }
    }
}

#endif
#endif
