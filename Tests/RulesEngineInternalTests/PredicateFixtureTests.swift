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

    private static let fixtures: [PredicateConformanceFixtureCase] = {
        let directory = PredicateConformanceFixtureLoader.inRepoFixturesDirectoryURL()
        return (try? PredicateConformanceFixtureLoader.loadCases(fromDirectory: directory)) ?? []
    }()

    @Test
    func fixturesLoadSuccessfully() throws {
        let directory = PredicateConformanceFixtureLoader.inRepoFixturesDirectoryURL()
        let cases = try PredicateConformanceFixtureLoader.loadCases(fromDirectory: directory)
        try #require(!cases.isEmpty, "Expected at least one in-repo predicate fixture")
    }

    @Test(arguments: Self.fixtures)
    func fixture(_ fixtureCase: PredicateConformanceFixtureCase) throws {
        try PredicateConformanceRunner.run(fixtureCase)
    }
}

extension PredicateConformanceFixtureCase: CustomTestStringConvertible {

    var testDescription: String { id }
}
