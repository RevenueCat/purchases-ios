//
//  PredicateFixtureTests.swift
//
//  Created by Antonio Pallares.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

/// Runs in-repo JSON predicate fixtures checked into
/// `Tests/UnitTests/RulesEngine/PredicateFixtures/`.
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
    /// the suite) by pinning the built-in case count. Update this count when
    /// built-in fixtures change. Shared Khepri cases can change independently.
    @Test
    func fixtureCountMatchesExpected() throws {
        let sharedFixture = PredicateConformanceFixtureLoader.repoFixturesDirectoryURL()
            .appendingPathComponent("predicate_conformance_v1.json")
        let hasSharedFixture = FileManager.default.fileExists(atPath: sharedFixture.path)
        let sharedCount = hasSharedFixture
            ? try PredicateConformanceFixtureLoader.loadCases(from: sharedFixture).count
            : 0
        try #require(!hasSharedFixture || sharedCount > 0, "Expected Khepri conformance cases")
        let expectedCount = 681 + sharedCount
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
#endif
