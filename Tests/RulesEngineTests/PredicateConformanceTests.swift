//
//  PredicateConformanceTests.swift
//
//  Created by Antonio Pallares.
//

import Testing

@testable import RulesEngine

/// Runs the khepri-generated audience predicate conformance fixtures as
/// individually-addressable test cases.
///
/// Download fixtures first:
/// `./scripts/rules_engine/download_predicate_conformance_fixtures.sh`
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
