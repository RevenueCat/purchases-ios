//
//  PredicateFixtureTests.swift
//
//  Created by Antonio Pallares.
//

import Testing

@testable import RulesEngineInternal

/// Runs in-repo JSON predicate fixtures checked into
/// `Tests/RulesEngineInternalTests/PredicateFixtures/`.
@Suite("Rules Engine Predicate Fixtures", .serialized)
struct PredicateFixtureTests {

    private static let fixtureIDs: [String] = {
        let directory = PredicateConformanceFixtureLoader.inRepoFixturesDirectoryURL()
        return (try? PredicateConformanceFixtureLoader.loadCases(fromDirectory: directory).map(\.id)) ?? []
    }()

    @Test
    func fixturesLoadSuccessfully() throws {
        let directory = PredicateConformanceFixtureLoader.inRepoFixturesDirectoryURL()
        let cases = try PredicateConformanceFixtureLoader.loadCases(fromDirectory: directory)
        try #require(!cases.isEmpty, "Expected at least one in-repo predicate fixture")
    }

    @Test(arguments: Self.fixtureIDs)
    func fixture(fixtureID: String) throws {
        let directory = PredicateConformanceFixtureLoader.inRepoFixturesDirectoryURL()
        let cases = try PredicateConformanceFixtureLoader.loadCases(fromDirectory: directory)
        guard let fixtureCase = cases.first(where: { $0.id == fixtureID }) else {
            Issue.record("Missing fixture \(fixtureID)")
            return
        }

        try PredicateConformanceRunner.run(fixtureCase)
    }
}
