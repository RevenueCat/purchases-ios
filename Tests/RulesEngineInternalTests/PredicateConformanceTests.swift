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

    private static let fixtures: [PredicateConformanceFixtureCase] = {
        (try? PredicateConformanceFixtureLoader.loadCases()) ?? []
    }()

    @Test
    func fixturesLoadSuccessfully() throws {
        try #require(!Self.fixtures.isEmpty, "Expected at least one khepri conformance fixture")
    }

    @Test(arguments: Self.fixtures)
    func fixture(_ fixtureCase: PredicateConformanceFixtureCase) throws {
        try PredicateConformanceRunner.run(fixtureCase)
    }
}
