//
//  PredicateConformanceFixture.swift
//
//  Created by Antonio Pallares.
//

import Foundation

@testable import RulesEngine

enum PredicateConformanceFixtureError: Error, CustomStringConvertible {

    case fixtureNotFound(path: String)
    case invalidEnvelope
    case invalidCase(id: String?)
    case invalidVariables(id: String)

    var description: String {
        switch self {
        case let .fixtureNotFound(path):
            return "Predicate conformance fixture not found at \(path)"
        case .invalidEnvelope:
            return "Predicate conformance fixture has an invalid envelope"
        case let .invalidCase(id):
            if let id {
                return "Predicate conformance fixture case \(id) is invalid"
            }
            return "Predicate conformance fixture contains an invalid case"
        case let .invalidVariables(id):
            return "Predicate conformance fixture case \(id) has invalid variables"
        }
    }
}

struct PredicateConformanceFixtureCase: Equatable {

    let id: String
    let predicate: Value
    let variables: [String: Value]
    let expected: Bool
}

enum PredicateConformanceFixtureLoader {

    static let fixtureEnvironmentVariable = "KHEPRI_PREDICATE_CONFORMANCE_FIXTURE_PATH"

    static func defaultFixtureURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Helpers
            .deletingLastPathComponent() // RulesEngineTests
            .appendingPathComponent("Fixtures/predicate_conformance_v1.json")
    }

    static func fixtureURL() throws -> URL {
        if let configuredPath = ProcessInfo.processInfo.environment[fixtureEnvironmentVariable],
           !configuredPath.isEmpty {
            return URL(fileURLWithPath: configuredPath, isDirectory: false)
        }
        return defaultFixtureURL()
    }

    static func loadCases() throws -> [PredicateConformanceFixtureCase] {
        let url = try fixtureURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PredicateConformanceFixtureError.fixtureNotFound(path: url.path)
        }

        let data = try Data(contentsOf: url)
        guard let envelope = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fixtures = envelope["fixtures"] as? [[String: Any]] else {
            throw PredicateConformanceFixtureError.invalidEnvelope
        }

        return try fixtures.map { rawCase in
            guard let id = rawCase["id"] as? String,
                  let expected = rawCase["expected"] as? Bool,
                  let predicateJSON = rawCase["predicate"],
                  let variablesJSON = rawCase["variables"] else {
                throw PredicateConformanceFixtureError.invalidCase(id: rawCase["id"] as? String)
            }

            guard case let .object(variables) = try Value.fromJSONObject(variablesJSON) else {
                throw PredicateConformanceFixtureError.invalidVariables(id: id)
            }

            return PredicateConformanceFixtureCase(
                id: id,
                predicate: try Value.fromJSONObject(predicateJSON),
                variables: variables,
                expected: expected
            )
        }
    }
}
