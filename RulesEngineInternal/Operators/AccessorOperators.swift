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
    /// Per the JSON Logic spec, the path and default arguments are
    /// recursively evaluated before lookup (e.g.
    /// `{"var": {"var": "active_path_key"}}` resolves `active_path_key`
    /// first and uses its string value as the path).
    ///
    /// - Parameter vars: The JSON Logic data scope — one evaluated `Value`
    ///   (usually an object) that `var` reads from. The name mirrors the
    ///   spec's "data" argument passed through recursive evaluation.
    static func opVar(args: Value, vars: Value) throws -> Value {
        let (path, defaultValue) = try resolveVarArgs(args, vars: vars)

        if let found = lookupVar(in: vars, path: path) {
            return found
        }
        if let defaultValue = defaultValue {
            return defaultValue
        }
        RulesEngine.logger.warn("missing variable: \(path)")
        return .null
    }

    /// `{"missing": ["a", "b.c"]}` returns the array of keys whose `var`
    /// lookup resolves to `null` (absent or `null` leaf) or to the empty
    /// string. Falsy non-empty values like `0`, `false`, or `[]` are NOT
    /// reported as missing. Returns `[]` when nothing is missing.
    ///
    /// Each key argument is recursively evaluated before lookup. If the
    /// first evaluated argument is itself an array, its elements are
    /// unpacked as the key list (e.g. `{"missing": {"merge": [...]}}`).
    static func opMissing(args: Value, vars: Value) throws -> Value {
        let evaluatedArgs: [Value]
        if case .array(let items) = args {
            evaluatedArgs = try items.map { try Evaluator.evaluateValue($0, vars: vars) }
        } else {
            // Singleton shorthand: `{"missing": "a"}` ≡ `{"missing": ["a"]}`.
            evaluatedArgs = [try Evaluator.evaluateValue(args, vars: vars)]
        }

        // Per JSON Logic spec: if the first arg resolves to an array,
        // treat its elements as the full key list.
        let keys: [Value]
        if let first = evaluatedArgs.first, case .array(let innerKeys) = first {
            keys = innerKeys
        } else {
            keys = evaluatedArgs
        }

        var missing: [Value] = []
        for key in keys {
            guard let path = keyAsPath(key) else { continue }
            if isMissingValue(varLookup(in: vars, path: path)) {
                missing.append(.string(path))
            }
        }
        return .array(missing)
    }

    /// `{"missing_some": [min_required, [path, ...]]}` returns the
    /// missing-keys array (same shape as `missing`) IF fewer than
    /// `min_required` of the requested paths are present. Otherwise
    /// returns `[]`.
    static func opMissingSome(args: Value, vars: Value) throws -> Value {
        let evaluated = try Operators.evalArgs(args, vars: vars)
        guard evaluated.count == 2 else {
            throw RuleError.typeMismatch(
                message: "operator 'missing_some' expects 2 arguments, got \(evaluated.count)"
            )
        }
        let needCountValue = evaluated[0]
        let options = evaluated[1]

        guard case .array(let items) = options else {
            throw RuleError.typeMismatch(
                message: "operator 'missing_some': second argument must be an array of paths, "
                    + "got \(options)"
            )
        }
        let total = items.count

        // Threshold uses JS `ToNumber` + `>=`. `NaN` and unparseable
        // strings never satisfy; `+Infinity` never satisfies for finite
        // present counts; `-Infinity` always satisfies.
        let need = jsToNumber(needCountValue)

        let missing = try opMissing(args: options, vars: vars)
        let missingCount: Int
        if case .array(let entries) = missing {
            missingCount = entries.count
        } else {
            missingCount = 0
        }

        if Double(total - missingCount) >= need {
            return .array([])
        }
        return missing
    }

    // MARK: - Helpers

    /// Recursively evaluate `var`'s arg(s) per the JSON Logic spec, then
    /// normalize the result into a `(path, default)` tuple.
    private static func resolveVarArgs(_ args: Value, vars: Value) throws -> (String, Value?) {
        if case .array(let items) = args {
            var evaluated: [Value] = []
            evaluated.reserveCapacity(items.count)
            for item in items {
                evaluated.append(try Evaluator.evaluateValue(item, vars: vars))
            }
            return parseVarArrayArgs(evaluated)
        }
        let evaluated = try Evaluator.evaluateValue(args, vars: vars)
        return (pathSegment(from: evaluated), nil)
    }

    private static func parseVarArrayArgs(_ items: [Value]) -> (String, Value?) {
        let path = pathSegment(from: items.first)
        let defaultValue: Value? = items.count >= 2 ? items[1] : nil
        if items.count > 2 {
            RulesEngine.logger.warn(
                "var: ignoring \(items.count - 2) extra arg(s); expected [path] or [path, default]"
            )
        }
        return (path, defaultValue)
    }

    /// Coerce the evaluated path argument to a string per
    /// `json-logic-js`'s `String(a).split(".")`. `nil`, `.null`, and
    /// `""` are treated as the empty path, which signals the caller
    /// to return the entire data scope.
    private static func pathSegment(from value: Value?) -> String {
        switch value {
        case .none, .some(.null):
            return ""
        case .some(let other):
            return jsString(other)
        }
    }

    private static func keyAsPath(_ value: Value) -> String? {
        if case .null = value { return nil }
        return jsString(value)
    }

    /// Resolve `path` the way `var` does. Empty path returns the entire
    /// data scope; a resolving path returns its value (including explicit
    /// `.null`); a non-resolving path returns `nil`.
    private static func lookupVar(in vars: Value, path: String) -> Value? {
        if path.isEmpty {
            return vars
        }
        return lookupPath(in: vars, path: path)
    }

    /// Like `lookupVar`, but maps a non-resolving path to `.null`
    /// instead of `nil` — the shape `missing` needs.
    private static func varLookup(in vars: Value, path: String) -> Value {
        lookupVar(in: vars, path: path) ?? .null
    }

    /// `missing` reports a key when its `var` lookup resolves to `null`
    /// or to the empty string. Falsy non-empty values (`0`, `false`,
    /// `[]`) are NOT missing.
    private static func isMissingValue(_ value: Value) -> Bool {
        switch value {
        case .null:
            return true
        case .string(let stringValue):
            return stringValue.isEmpty
        default:
            return false
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
}
