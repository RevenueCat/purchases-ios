//
//  SemverOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Name used in this operator's error messages.
private let operatorName = "rc.semverCompare"

extension RulesEngine {

    /// `rc.semverCompare` — three-way version comparison following
    /// Semantic Versioning 2.0.0 precedence.
    enum SemverOperator {

        /// `{"rc.semverCompare": [left, right]}` — `-1`, `0`, or `1`, so rules
        /// compare with the existing operators:
        /// `{">=": [{"rc.semverCompare": [{"var": "appVersion"}, "2.1.0"]}, 0]}`.
        ///
        /// The built-in `<` / `>` compare version strings lexicographically,
        /// which puts `"10.0.0"` below `"9.0.0"`.
        ///
        /// Both operands must be strings that parse, otherwise
        /// `EvaluationError.typeMismatch`. Returning `0` for unparseable input
        /// would report "equal" for a missing variable or a typo, quietly
        /// matching every rule built on it. Arity is exact for the same reason.
        static func opSemverCompare(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Operators.evalArgs(args, vars: vars)

            guard evaluated.count == 2 else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expects 2 arguments, "
                        + "got \(evaluated.count)"
                )
            }

            let left = try SemanticVersion(parsing: evaluated[0])
            let right = try SemanticVersion(parsing: evaluated[1])
            return .int(Int64(left.compare(to: right)))
        }
    }
}

/// A parsed version: core components padded to three, plus prerelease
/// identifiers (empty for a release version). Build metadata is dropped, since
/// semver §10 excludes it from precedence.
///
/// Two deliberate concessions to real-world version strings: a missing minor or
/// patch is `0` (`"2.1"` ≡ `"2.1.0"`), and leading zeros are accepted
/// (`"1.02.0"` ≡ `"1.2.0"`) even though the spec forbids them.
private struct SemanticVersion {

    private static let coreComponents = 3

    let core: [Int]
    let prerelease: [String]

    init(parsing value: RulesEngine.Value) throws {
        guard case .string(let string) = value else {
            throw RulesEngine.EvaluationError.typeMismatch(
                message: "operator '\(operatorName)' expected version strings, got \(value)"
            )
        }

        let withoutBuild = string.prefix { $0 != "+" }

        let coreText: Substring
        let prereleaseText: Substring?
        if let separator = withoutBuild.firstIndex(of: "-") {
            coreText = withoutBuild[..<separator]
            prereleaseText = withoutBuild[withoutBuild.index(after: separator)...]
        } else {
            coreText = withoutBuild
            prereleaseText = nil
        }

        self.core = try Self.parseCore(coreText, in: string)
        self.prerelease = try Self.parsePrerelease(prereleaseText, in: string)
    }

    func compare(to other: SemanticVersion) -> Int {
        for (lhs, rhs) in zip(self.core, other.core) where lhs != rhs {
            return lhs < rhs ? -1 : 1
        }

        switch (self.prerelease.isEmpty, other.prerelease.isEmpty) {
        case (true, true):
            return 0
        case (true, false):
            // A release outranks any prerelease of the same core.
            return 1
        case (false, true):
            return -1
        case (false, false):
            return Self.compare(prerelease: self.prerelease, with: other.prerelease)
        }
    }

    private static func parseCore(_ text: Substring, in original: String) throws -> [Int] {
        let components = text.split(separator: ".", omittingEmptySubsequences: false)

        guard !components.isEmpty, components.count <= Self.coreComponents else {
            throw Self.invalid(original)
        }

        var core = try components.map { component -> Int in
            guard let number = Self.numericIdentifier(component) else {
                throw Self.invalid(original)
            }
            return number
        }

        core.append(contentsOf: repeatElement(0, count: Self.coreComponents - core.count))
        return core
    }

    private static func parsePrerelease(
        _ text: Substring?,
        in original: String
    ) throws -> [String] {
        guard let text else { return [] }

        return try text.split(separator: ".", omittingEmptySubsequences: false).map { identifier in
            guard !identifier.isEmpty, identifier.allSatisfy(Self.isIdentifierCharacter) else {
                throw Self.invalid(original)
            }
            return String(identifier)
        }
    }

    /// Semver §11: identifiers are compared field by field. Numeric fields
    /// compare numerically, alphanumeric ones by ASCII order, and a numeric
    /// field always ranks below an alphanumeric one. When every shared field
    /// ties, the version with more fields wins.
    private static func compare(prerelease lhs: [String], with rhs: [String]) -> Int {
        for (left, right) in zip(lhs, rhs) {
            switch (Self.numericIdentifier(left), Self.numericIdentifier(right)) {
            case (.some(let left), .some(let right)) where left != right:
                return left < right ? -1 : 1
            case (.some, .none):
                return -1
            case (.none, .some):
                return 1
            case (.none, .none) where left != right:
                return left < right ? -1 : 1
            default:
                continue
            }
        }

        if lhs.count != rhs.count {
            return lhs.count < rhs.count ? -1 : 1
        }
        return 0
    }

    /// A numeric identifier is digits only. `Int(_:)` alone would also accept a
    /// signed identifier like `-1`, which is alphanumeric here.
    private static func numericIdentifier<S: StringProtocol>(_ text: S) -> Int? {
        guard !text.isEmpty, text.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return Int(text)
    }

    private static func isIdentifierCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "-")
    }

    private static func invalid(_ version: String) -> RulesEngine.EvaluationError {
        .typeMismatch(
            message: "operator '\(operatorName)' could not parse version '\(version)'"
        )
    }
}
