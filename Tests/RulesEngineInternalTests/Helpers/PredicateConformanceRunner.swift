//
//  PredicateConformanceRunner.swift
//
//  Created by Antonio Pallares.
//

import Testing

@testable import RulesEngineInternal

enum PredicateConformanceRunner {

    static func run(_ fixture: PredicateConformanceFixtureCase) throws {
        if let expectedWarnings = fixture.expectedWarnings {
            let logger = CapturingLogger()
            let previousLogger = RulesEngine.logger
            RulesEngine.setLogger(logger)
            defer { RulesEngine.setLogger(previousLogger) }
            try assertExpectedOutcome(fixture: fixture)
            assertWarnings(
                logger: logger,
                expected: expectedWarnings,
                fixtureID: fixture.id
            )
        } else {
            try assertExpectedOutcome(fixture: fixture)
        }
    }

    private static func assertExpectedOutcome(fixture: PredicateConformanceFixtureCase) throws {
        switch fixture.expected {
        case .boolean(let expected):
            let result = try Evaluator.evaluate(
                predicate: fixture.predicate,
                variables: fixture.variables
            )
            #expect(result == expected, "Fixture \(fixture.id)")

        case .error(let expectedError):
            do {
                _ = try Evaluator.evaluate(
                    predicate: fixture.predicate,
                    variables: fixture.variables
                )
                Issue.record(
                    "Fixture \(fixture.id) expected error \(expectedError.kind) but succeeded"
                )
            } catch let error as RuleError {
                guard matchesExpected(error: error, expected: expectedError) else {
                    Issue.record(
                        "Fixture \(fixture.id) threw \(error), expected \(expectedError.kind)"
                    )
                    return
                }
            } catch {
                Issue.record(
                    "Fixture \(fixture.id) threw \(error), expected \(expectedError.kind)"
                )
            }
        }
    }

    private static func matchesExpected(error: RuleError, expected: ExpectedError) -> Bool {
        switch expected.kind {
        case "parse":
            if case .parse = error { return true }

        case "typeMismatch":
            if case .typeMismatch = error { return true }

        case "unsupportedOperator":
            if case .unsupportedOperator(let name) = error {
                if let expectedName = expected.operator {
                    return name == expectedName
                }
                return true
            }

        default:
            break
        }
        return false
    }

    private static func assertWarnings(
        logger: CapturingLogger,
        expected: ExpectedWarnings,
        fixtureID: String
    ) {
        let warnings = logger.warnings
        if let count = expected.count {
            #expect(warnings.count == count, "Fixture \(fixtureID) warning count")
        }
        for substring in expected.contains {
            #expect(
                warnings.contains(where: { $0.contains(substring) }),
                "Fixture \(fixtureID) missing warning containing \"\(substring)\""
            )
        }
    }
}
