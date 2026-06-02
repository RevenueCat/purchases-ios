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

    var description: String {
        switch self {
        case let .fixtureNotFound(path):
            return "Predicate conformance fixture not found at \(path)"
        case let .directoryNotFound(path):
            return "Predicate fixture directory not found at \(path)"
        }
    }
}

enum ExpectedOutcome: Equatable, Decodable {

    case boolean(Bool)
    case error(ExpectedError)

    init(from decoder: Decoder) throws {
        if let boolean = try? decoder.singleValueContainer().decode(Bool.self) {
            self = .boolean(boolean)
        } else {
            self = .error(try ExpectedError(from: decoder))
        }
    }
}

struct ExpectedError: Equatable, Decodable {

    let kind: String
    let `operator`: String?

    enum CodingKeys: String, CodingKey {
        case kind = "error"
        case `operator`
    }
}

struct ExpectedWarnings: Equatable, Decodable {

    /// Substrings that must each appear in some emitted warning. An empty list
    /// asserts that no warning is emitted at all.
    let contains: [String]

    enum CodingKeys: String, CodingKey {
        case contains
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.contains = try container.decodeIfPresent([String].self, forKey: .contains) ?? []
    }
}

struct PredicateConformanceFixtureCase: Equatable, Decodable, Identifiable, Sendable {

    let id: String
    let description: String?
    let predicate: Value
    let variables: [String: Value]
    let expected: ExpectedOutcome
    let expectedWarnings: ExpectedWarnings?
}

enum PredicateConformanceFixtureLoader {

    private struct Envelope: Decodable {
        let fixtures: [PredicateConformanceFixtureCase]
    }

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
        return try JSONDecoder().decode(Envelope.self, from: data).fixtures
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
}
