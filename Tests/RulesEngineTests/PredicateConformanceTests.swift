//
//  PredicateConformanceTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

/// Runs the khepri-generated audience predicate conformance fixtures as
/// individually-addressable XCTest cases.
///
/// Download fixtures first:
/// `./scripts/rules_engine/download_predicate_conformance_fixtures.sh`
final class PredicateConformanceTests: XCTestCase {

    private static var cases: [PredicateConformanceFixtureCase] = []
    private static var didLoadCases = false
    private static var loadFailure: Error?

    private var caseIndex: Int?

    convenience init(fixtureIndex index: Int) {
        self.init(selector: #selector(runFixtureCase))
        self.caseIndex = index
    }

    override var name: String {
        if let caseIndex,
           caseIndex >= 0,
           caseIndex < Self.cases.count {
            return Self.testName(for: Self.cases[caseIndex].id)
        }
        return "test/fixture_load_failed"
    }

    /// Ensures XCTest registers this case class so `defaultTestSuite` runs.
    func testBootstrap() {
        XCTAssertTrue(true)
    }

    override class var defaultTestSuite: XCTestSuite {
        let suite = XCTestSuite(name: String(describing: Self.self))
        loadCasesIfNeeded()

        if loadFailure != nil {
            suite.addTest(PredicateConformanceTests(selector: #selector(failToLoadFixtures)))
            return suite
        }

        for index in cases.indices {
            suite.addTest(PredicateConformanceTests(fixtureIndex: index))
        }
        return suite
    }

    @objc
    private func runFixtureCase() throws {
        Self.loadCasesIfNeeded()
        guard let caseIndex,
              caseIndex >= 0,
              caseIndex < Self.cases.count else {
            return XCTFail("Missing fixture index")
        }

        try evaluateFixture(Self.cases[caseIndex])
    }

    @objc
    private func failToLoadFixtures() {
        Self.loadCasesIfNeeded()
        if let loadFailure = Self.loadFailure {
            XCTFail("Failed to load predicate conformance fixtures: \(loadFailure.localizedDescription)")
        } else {
            XCTFail("Failed to load predicate conformance fixtures: no cases found")
        }
    }

    private static func loadCasesIfNeeded() {
        guard !didLoadCases else {
            return
        }
        didLoadCases = true
        do {
            cases = try PredicateConformanceFixtureLoader.loadCases()
        } catch {
            loadFailure = error
        }
    }

    private func evaluateFixture(_ fixtureCase: PredicateConformanceFixtureCase) throws {
        do {
            let result = try Evaluator.evaluate(
                predicate: fixtureCase.predicate,
                variables: fixtureCase.variables
            )
            XCTAssertEqual(
                result,
                fixtureCase.expected,
                "Fixture \(fixtureCase.id)"
            )
        } catch RuleError.unsupportedOperator(let name) {
            XCTFail("Fixture \(fixtureCase.id) uses unsupported operator \(name)")
        } catch {
            XCTFail("Fixture \(fixtureCase.id) threw \(error)")
        }
    }

    private static func testName(for fixtureID: String) -> String {
        let sanitized = fixtureID
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return "test/\(sanitized)"
    }
}
