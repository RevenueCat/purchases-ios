//
//  PredicateConformanceFixture.swift
//
//  Created by Antonio Pallares.
//

import Foundation

@testable import RulesEngineInternal

enum PredicateConformanceFixtureError: Error, CustomStringConvertible {

    case fixtureNotFound(path: String)
    case directoryNotFound(path: String)
    case invalidEnvelope
    case invalidCase(id: String?)
    case invalidVariables(id: String)

    var description: String {
        switch self {
        case let .fixtureNotFound(path):
            return "Predicate conformance fixture not found at \(path)"
        case let .directoryNotFound(path):
            return "Predicate fixture directory not found at \(path)"
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

enum ExpectedOutcome: Equatable {

    case boolean(Bool)
    case error(ExpectedError)
}

struct ExpectedError: Equatable {

    let kind: String
    let `operator`: String?
}

struct ExpectedWarnings: Equatable {

    let count: Int?
    let contains: [String]
}

struct PredicateConformanceFixtureCase: Equatable {

    let id: String
    let description: String?
    let predicate: Value
    let variables: [String: Value]
    let expected: ExpectedOutcome
    let expectedWarnings: ExpectedWarnings?
}

enum PredicateConformanceFixtureLoader {

    static let fixtureEnvironmentVariable = "KHEPRI_PREDICATE_CONFORMANCE_FIXTURE_PATH"

    static func defaultFixtureURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Helpers
            .deletingLastPathComponent() // RulesEngineTests
            .appendingPathComponent("Fixtures/predicate_conformance_v1.json")
    }

    static func inRepoFixturesDirectoryURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Helpers
            .deletingLastPathComponent() // RulesEngineInternalTests
            .appendingPathComponent("PredicateFixtures", isDirectory: true)
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
        return try loadCases(from: url)
    }

    static func loadCases(from url: URL) throws -> [PredicateConformanceFixtureCase] {
        let data = try Data(contentsOf: url)
        guard let envelope = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fixtures = envelope["fixtures"] as? [[String: Any]] else {
            throw PredicateConformanceFixtureError.invalidEnvelope
        }

        return try fixtures.map { rawCase in
            guard let id = rawCase["id"] as? String,
                  let predicateJSON = rawCase["predicate"],
                  let variablesJSON = rawCase["variables"],
                  let expectedJSON = rawCase["expected"] else {
                throw PredicateConformanceFixtureError.invalidCase(id: rawCase["id"] as? String)
            }

            guard case let .object(variables) = try Value.fromJSONObject(variablesJSON) else {
                throw PredicateConformanceFixtureError.invalidVariables(id: id)
            }

            return PredicateConformanceFixtureCase(
                id: id,
                description: rawCase["description"] as? String,
                predicate: try Value.fromJSONObject(predicateJSON),
                variables: variables,
                expected: try parseExpected(expectedJSON, id: id),
                expectedWarnings: parseExpectedWarnings(rawCase["expectedWarnings"])
            )
        }
    }

    static func loadCases(fromDirectory dir: URL) throws -> [PredicateConformanceFixtureCase] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw PredicateConformanceFixtureError.directoryNotFound(path: dir.path)
        }

        let urls = try FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return try urls.flatMap { try loadCases(from: $0) }
    }

    private static func parseExpected(_ raw: Any, id: String) throws -> ExpectedOutcome {
        if let value = raw as? Bool {
            return .boolean(value)
        }
        if let dict = raw as? [String: Any],
           let errorKind = dict["error"] as? String {
            return .error(ExpectedError(
                kind: errorKind,
                operator: dict["operator"] as? String
            ))
        }
        throw PredicateConformanceFixtureError.invalidCase(id: id)
    }

    private static func parseExpectedWarnings(_ raw: Any?) -> ExpectedWarnings? {
        guard let dict = raw as? [String: Any] else {
            return nil
        }
        let count: Int?
        if let rawCount = dict["count"] {
            count = rawCount as? Int ?? (rawCount as? NSNumber)?.intValue
        } else {
            count = nil
        }
        let contains = dict["contains"] as? [String] ?? []
        return ExpectedWarnings(count: count, contains: contains)
    }
}
