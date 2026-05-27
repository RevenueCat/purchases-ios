//
//  PredicateConformanceTests.swift
//
//  Created by Antonio Pallares.
//

import Testing

@testable import RulesEngineInternal

/// Runs khepri-generated audience predicate conformance fixtures.
///
/// Uses Swift Testing `@Test(arguments:)` so each fixture is reported as its own
/// test case in CI (CircleCI Tests tab / JUnit from the xcresult bundle).
///
/// Fixtures are downloaded automatically when building or testing
/// `RulesEngineInternalTests`. To refresh: delete the file under
/// `Tests/RulesEngineInternalTests/Fixtures/` or set
/// `KHEPRI_FORCE_PREDICATE_CONFORMANCE_FIXTURE_DOWNLOAD=1`.
@Suite("Khepri Predicate Conformance")
struct PredicateConformanceTests {

    private static let fixtureIDs: [String] = {
        (try? PredicateConformanceFixtureLoader.loadCases().map(\.id)) ?? []
    }()

    @Test
    func fixturesLoadSuccessfully() throws {
        let cases = try PredicateConformanceFixtureLoader.loadCases()
        try #require(!cases.isEmpty, "Expected at least one khepri conformance fixture")
    }

    @Test(arguments: Self.fixtureIDs)
    func fixture(fixtureID: String) throws {
        let cases = try PredicateConformanceFixtureLoader.loadCases()
        guard let fixtureCase = cases.first(where: { $0.id == fixtureID }) else {
            Issue.record("Missing fixture \(fixtureID)")
            return
        }

        do {
            let result = try Evaluator.evaluate(
                predicate: fixtureCase.predicate,
                variables: fixtureCase.variables
            )
            #expect(
                result == fixtureCase.expected,
                "Fixture \(fixtureCase.id)"
            )
        } catch RuleError.unsupportedOperator(let name) {
            Issue.record("Fixture \(fixtureCase.id) uses unsupported operator \(name)")
        } catch {
            Issue.record("Fixture \(fixtureCase.id) threw \(error)")
        }
    }
}
