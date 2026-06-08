//
//  PredicateFixtureTests.swift
//
//  Created by Antonio Pallares.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if canImport(Testing)

import Testing

@testable import RulesEngineInternal

/// Runs in-repo JSON predicate fixtures checked into
/// `Tests/RulesEngineInternalTests/PredicateFixtures/`.
@Suite("Rules Engine Predicate Fixtures", .serialized)
struct PredicateFixtureTests {

    private static let fixtures: [PredicateConformanceFixtureCase] = {
        let directory = PredicateConformanceFixtureLoader.repoFixturesDirectoryURL()
        return (try? PredicateConformanceFixtureLoader.loadCases(fromDirectory: directory)) ?? []
    }()

    @Test
    func fixturesLoadSuccessfully() throws {
        try #require(!Self.fixtures.isEmpty, "Expected at least one in-repo predicate fixture")
    }

    /// Guards against a fixture file silently failing to load (and shrinking
    /// the suite) by pinning the total number of cases. Bump this whenever
    /// fixtures are added or removed.
    @Test
    func fixtureCountMatchesExpected() {
        let expectedCount = 307
        #expect(
            Self.fixtures.count == expectedCount,
            "Expected \(expectedCount) fixtures, loaded \(Self.fixtures.count)"
        )
    }

    @Test(arguments: Self.fixtures)
    func fixture(_ fixtureCase: PredicateConformanceFixtureCase) throws {
        try PredicateConformanceRunner.run(fixtureCase)
    }
}

extension PredicateConformanceFixtureCase: CustomTestStringConvertible {

    var testDescription: String { id }
}

#endif
