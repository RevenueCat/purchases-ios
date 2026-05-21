//
//  AccessorOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// `var` and `missing` — the data-accessor operators.
enum AccessorOperators {

    /// `{"var": "subscriber.last_seen_country"}` — look up a (possibly
    /// nested) value by dot-path. `{"var": ["path", default]}` returns
    /// `default` when the path is missing. `{"var": ""}` returns the entire
    /// data scope.
    ///
    /// Per the JSON Logic spec, the path argument is recursively evaluated
    /// before lookup, so callers can compute paths dynamically — e.g.
    /// `{"var": {"var": "active_path_key"}}` resolves `active_path_key`
    /// first and uses its string value as the actual path. In the array
    /// form, the default argument is evaluated the same way.
    ///
    /// Variable lookup uses **strict JSON Logic dot-path semantics on
    /// nested objects**. There is no flat-key fallback (i.e. we do not also
    /// try the literal dotted string as a single key in the top-level map).
    static func opVar(args: Value, vars: Value) throws -> Value {
        let (path, defaultValue) = try resolveVarArgs(args, vars: vars)

        if path.isEmpty {
            return vars
        }

        if let found = lookupPath(in: vars, path: path) {
            return found
        }
        if let defaultValue = defaultValue {
            return defaultValue
        }
        Rules.logger.warn("missing variable: \(path)")
        return .null
    }

    /// `{"missing": ["a", "b.c"]}` returns the array of keys (as strings)
    /// that are NOT present in the data. Returns `[]` when nothing is
    /// missing.
    ///
    /// Per the JSON Logic spec, each key argument is recursively evaluated
    /// before lookup, so dynamic key lists like
    /// `{"missing": [{"var": "key_to_check"}]}` work. If the first
    /// (possibly only) evaluated argument is itself an array (typically the
    /// output of another operator), its elements are unpacked as the key
    /// list — this is how `{"missing": {"merge": [["a"], ["b"]]}}` is meant
    /// to behave.
    static func opMissing(args: Value, vars: Value) throws -> Value {
        let evaluatedArgs: [Value]
        if case .array(let items) = args {
            evaluatedArgs = try items.map { try Evaluator.evaluateValue($0, vars: vars) }
        } else {
            // Singleton shorthand: `{"missing": "a"}` ≡ `{"missing": ["a"]}`.
            evaluatedArgs = [try Evaluator.evaluateValue(args, vars: vars)]
        }

        // Per JSON Logic spec: if the first arg resolves to an array, treat
        // its elements as the full key list (lets nested operators feed
        // `missing` a computed key set).
        let keys: [Value]
        if let first = evaluatedArgs.first, case .array(let innerKeys) = first {
            keys = innerKeys
        } else {
            keys = evaluatedArgs
        }

        var missing: [Value] = []
        for key in keys {
            guard let path = keyAsPath(key) else { continue }
            if lookupPath(in: vars, path: path) == nil {
                missing.append(.string(path))
            }
        }
        return .array(missing)
    }

    // MARK: - Helpers

    /// Recursively evaluate `var`'s arg(s) per the JSON Logic spec, then
    /// normalize the result into a `(path, default)` tuple. The array form
    /// evaluates each element in place; the singleton form evaluates the
    /// (conceptually wrapped) lone argument so that constructs like
    /// `{"var": {"var": "key"}}` resolve to a dynamic path string.
    private static func resolveVarArgs(_ args: Value, vars: Value) throws -> (String, Value?) {
        if case .array(let items) = args {
            var evaluated: [Value] = []
            evaluated.reserveCapacity(items.count)
            for item in items {
                evaluated.append(try Evaluator.evaluateValue(item, vars: vars))
            }
            return try parseVarArrayArgs(evaluated)
        }
        let evaluated = try Evaluator.evaluateValue(args, vars: vars)
        return (try pathSegment(from: evaluated), nil)
    }

    private static func parseVarArrayArgs(_ items: [Value]) throws -> (String, Value?) {
        let path = try pathSegment(from: items.first)
        let defaultValue: Value? = items.count >= 2 ? items[1] : nil
        if items.count > 2 {
            Rules.logger.warn(
                "var: ignoring \(items.count - 2) extra arg(s); expected [path] or [path, default]"
            )
        }
        return (path, defaultValue)
    }

    private static func pathSegment(from value: Value?) throws -> String {
        switch value {
        case .none, .some(.null):
            return ""
        case .some(.string(let value)):
            return value
        case .some(.int(let value)):
            return String(value)
        case .some(.float(let value)):
            return formatNumber(value)
        case .some(let other):
            throw RuleError.typeMismatch(
                message: "var path must be a string or number, got \(other)"
            )
        }
    }

    private static func keyAsPath(_ value: Value) -> String? {
        switch value {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .float(let value):
            return formatNumber(value)
        default:
            return nil
        }
    }

    /// Walk `vars` following `path` (dot-separated). Numeric segments index
    /// into arrays; string segments key into objects. Returns `nil` if any
    /// segment can't resolve.
    private static func lookupPath(in vars: Value, path: String) -> Value? {
        var current = vars
        for segment in path.split(separator: ".", omittingEmptySubsequences: false) {
            switch current {
            case .object(let map):
                guard let next = map[String(segment)] else { return nil }
                current = next
            case .array(let items):
                guard let idx = Int(segment), idx >= 0, idx < items.count else { return nil }
                current = items[idx]
            default:
                return nil
            }
        }
        return current
    }

    /// Render a `Double` the way JSON Logic / JS would — `1.0` becomes
    /// `"1"`, `1.5` stays `"1.5"`. Used so a numeric path like `var: 1.0`
    /// looks up `"1"` (i.e. array index 1), not `"1.0"`.
    ///
    /// `Int64(exactly:)` returns `nil` for non-integer, out-of-range,
    /// NaN, and ±Infinity inputs, so the fall-through to `String(value)`
    /// covers each of those without a manual guard.
    private static func formatNumber(_ value: Double) -> String {
        if let intValue = Int64(exactly: value) {
            return String(intValue)
        }
        return String(value)
    }
}
