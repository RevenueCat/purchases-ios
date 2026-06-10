//
//  PredicateConformanceRunner.swift
//
//  Created by Antonio Pallares.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Testing

@testable import RulesEngineInternal

enum PredicateConformanceRunner {

    /// Test-only numeric constants seeded into every fixture's variable
    /// scope so fixtures can reference values JSON cannot express as a
    /// literal (`±Infinity`). These exist ONLY in the test harness — they
    /// are never part of the production engine or real rule data.
    private static let reservedConstants: [String: Value] = [
        "+Infinity": .float(.infinity),
        "-Infinity": .float(-.infinity)
    ]

    /// Fixture-declared variables take precedence over the reserved
    /// constants on a name collision.
    private static func scope(for fixture: PredicateConformanceFixtureCase) -> [String: Value] {
        reservedConstants.merging(fixture.variables) { _, fixtureValue in fixtureValue }
    }

    static func run(_ fixture: PredicateConformanceFixtureCase) throws {
        if fixture.expectedWarnings != nil || fixture.expectedLogs != nil {
            let logger = CapturingLogger()
            try RulesEngine.$scopedLogger.withValue(logger) {
                try assertExpectedOutcome(fixture: fixture)
                if let expectedWarnings = fixture.expectedWarnings {
                    assertWarnings(logger: logger, expected: expectedWarnings, fixtureID: fixture.id)
                }
                if let expectedLogs = fixture.expectedLogs {
                    assertLogs(logger: logger, expected: expectedLogs, fixtureID: fixture.id)
                }
            }
        } else {
            try assertExpectedOutcome(fixture: fixture)
        }
    }

    private static func assertExpectedOutcome(fixture: PredicateConformanceFixtureCase) throws {
        switch fixture.expected {
        case .boolean(let expected):
            let result = try Evaluator.evaluate(
                predicate: fixture.predicate,
                variables: scope(for: fixture)
            )
            #expect(result == expected, "Fixture \(fixture.id)")

        case .error(let expectedError):
            do {
                _ = try Evaluator.evaluate(
                    predicate: fixture.predicate,
                    variables: scope(for: fixture)
                )
                Issue.record(
                    "Fixture \(fixture.id) expected error \(expectedError.kind) but succeeded"
                )
            } catch let error as RulesEngine.EvaluationError {
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

    private static func matchesExpected(error: RulesEngine.EvaluationError, expected: ExpectedError) -> Bool {
        switch expected.kind {
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
        guard !expected.contains.isEmpty else {
            #expect(
                warnings.isEmpty,
                "Fixture \(fixtureID) expected no warnings, got \(warnings)"
            )
            return
        }
        for substring in expected.contains {
            #expect(
                warnings.contains(where: { $0.contains(substring) }),
                "Fixture \(fixtureID) missing warning containing \"\(substring)\""
            )
        }
    }

    private static func assertLogs(
        logger: CapturingLogger,
        expected: [String],
        fixtureID: String
    ) {
        let logs = logger.logs
        #expect(
            logs == expected,
            "Fixture \(fixtureID) expected logs \(expected), got \(logs)"
        )
    }
}

#endif
#endif
