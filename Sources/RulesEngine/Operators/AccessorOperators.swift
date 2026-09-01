//
//  AccessorOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// `var` and `missing` — the data-accessor operators.
    enum AccessorOperators {

        /// `{"var": "subscriber.last_seen_country"}` — look up a (possibly
        /// nested) value by dot-path. `{"var": ["path", default]}` returns
        /// `default` when the path is missing; an `undefined` default is
        /// coerced to `.null`, mirroring `json-logic-js`'s
        /// `not_found = (b === undefined) ? null : b`. `{"var": ""}` returns
        /// the entire data scope.
        ///
        /// A path that does not resolve and carries no default throws
        /// `EvaluationError.unresolvedVariable` rather than degrading to
        /// `null`. A key that *is* present but holds an explicit `null` is a
        /// known value, not a missing one, and resolves normally.
        ///
        /// Per the JSON Logic spec, the path and default arguments are
        /// recursively evaluated before lookup (e.g.
        /// `{"var": {"var": "active_path_key"}}` resolves `active_path_key`
        /// first and uses its string value as the path).
        ///
        /// - Parameter vars: The JSON Logic evaluation scope — `current` is
        ///   the data `var` reads from; path/default args evaluate against
        ///   `current` as well.
        static func opVar(args: Value, vars: Scope) throws -> Value {
            try resolveVar(
                args: args,
                lookup: { lookupInScope(vars, path: $0) },
                vars: vars,
                operatorName: "var"
            )
        }

        /// Shared lookup for `var` and `rc.rootVar`. Path and default args
        /// evaluate against `vars.current`; `lookup` performs the final
        /// resolution, which differs per operator — `var` also sees `rc.let`
        /// bindings, while `rc.rootVar` reads the root and nothing else.
        static func resolveVar(
            args: Value,
            lookup: (String) -> Value?,
            vars: Scope,
            operatorName: String
        ) throws -> Value {
            let (path, defaultValue) = try resolveVarArgs(args, vars: vars, operatorName: operatorName)

            if let found = lookup(path) {
                return found
            }
            if let defaultValue = defaultValue {
                // json-logic-js coerces an `undefined` default to `null`.
                if case .undefined = defaultValue { return .null }
                return defaultValue
            }
            throw RulesEngine.EvaluationError.unresolvedVariable(path: path)
        }

        /// `{"missing": ["a", "b.c"]}` returns the array of keys whose `var`
        /// lookup resolves to `null` (absent or `null` leaf) or to the empty
        /// string. Falsy non-empty values like `0`, `false`, or `[]` are NOT
        /// reported as missing. Returns `[]` when nothing is missing.
        ///
        /// Each key argument is recursively evaluated before lookup. If the
        /// first evaluated argument is itself an array, its elements are
        /// unpacked as the key list (e.g. `{"missing": {"merge": [...]}}`).
        static func opMissing(args: Value, vars: Scope) throws -> Value {
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
                if isMissingValue(lookupInScope(vars, path: path) ?? .null) {
                    missing.append(.string(path))
                }
            }
            return .array(missing)
        }

        /// `{"missing_some": [min_required, [path, ...]]}` returns the
        /// missing-keys array (same shape as `missing`) IF fewer than
        /// `min_required` of the requested paths are present. Otherwise
        /// returns `[]`.
        static func opMissingSome(args: Value, vars: Scope) throws -> Value {
            let evaluated = try Operators.evalArgs(args, vars: vars)
            guard evaluated.count == 2 else {
                throw RulesEngine.EvaluationError.typeMismatch(
                    message: "operator 'missing_some' expects 2 arguments, got \(evaluated.count)"
                )
            }
            let needCountValue = evaluated[0]
            let options = evaluated[1]

            // json-logic-js computes `missing.apply(this, [options])` for the
            // keys, then reads `options.length` for the threshold. So the key
            // set and the threshold count come from *different* views of
            // `options`:
            //   - array  → its elements are the keys; length = element count
            //   - string → the *whole string* is a single key; length = its
            //              UTF-16 code-unit count (matching JS `String.length`),
            //              so a long string can satisfy a larger threshold while
            //              only ever contributing one key
            //   - null   → no keys; `length` is `undefined`, which makes the
            //              threshold comparison `NaN >= need` (always false), so
            //              the missing list is returned unconditionally
            //   - other  → `Function.prototype.apply` throws a `TypeError`
            let keys: [Value]
            let total: Int?
            switch options {
            case .array(let items):
                keys = items
                total = items.count
            case .string(let string):
                keys = [.string(string)]
                total = string.utf16.count
            case .null, .undefined:
                keys = []
                total = nil
            default:
                throw RulesEngine.EvaluationError.typeMismatch(
                    message: "operator 'missing_some': second argument must be array-like, "
                        + "got \(options)"
                )
            }

            // Threshold uses JS `ToNumber` + `>=`. `NaN` and unparseable
            // strings never satisfy; `+Infinity` never satisfies for finite
            // present counts; `-Infinity` always satisfies.
            let need = jsToNumber(needCountValue)

            let missing = try opMissing(args: .array(keys), vars: vars)
            let missingCount: Int
            if case .array(let entries) = missing {
                missingCount = entries.count
            } else {
                missingCount = 0
            }

            if let total, Double(total - missingCount) >= need {
                return .array([])
            }
            return missing
        }

        // MARK: - Helpers

        /// Recursively evaluate `var`'s arg(s) per the JSON Logic spec, then
        /// normalize the result into a `(path, default)` tuple.
        private static func resolveVarArgs(
            _ args: Value,
            vars: Scope,
            operatorName: String
        ) throws -> (String, Value?) {
            if case .array(let items) = args {
                var evaluated: [Value] = []
                evaluated.reserveCapacity(items.count)
                for item in items {
                    evaluated.append(try Evaluator.evaluateValue(item, vars: vars))
                }
                return parseVarArrayArgs(evaluated, operatorName: operatorName)
            }
            let evaluated = try Evaluator.evaluateValue(args, vars: vars)
            return (pathSegment(from: evaluated), nil)
        }

        private static func parseVarArrayArgs(_ items: [Value], operatorName: String) -> (String, Value?) {
            let path = pathSegment(from: items.first)
            let defaultValue: Value? = items.count >= 2 ? items[1] : nil
            if items.count > 2 {
                RulesEngine.logger.warn(
                    "\(operatorName): ignoring \(items.count - 2) extra arg(s); expected [path] or [path, default]"
                )
            }
            return (path, defaultValue)
        }

        /// Coerce the evaluated path argument to a string per
        /// `json-logic-js`'s `String(a).split(".")`. `nil`, `.null`,
        /// `.undefined`, and `""` are treated as the empty path, which signals
        /// the caller to return the entire data scope — matching json-logic-js's
        /// `typeof a === "undefined" || a === "" || a === null` guard.
        private static func pathSegment(from value: Value?) -> String {
            switch value {
            case .none, .some(.null), .some(.undefined):
                return ""
            case .some(let other):
                return jsString(other)
            }
        }

        /// `missing` routes each key through `var`, where `.null`/`.undefined`
        /// resolve to the full scope (so they are never "missing"). Returning
        /// `nil` here skips them, matching json-logic-js.
        private static func keyAsPath(_ value: Value) -> String? {
            switch value {
            case .null, .undefined:
                return nil
            default:
                return jsString(value)
            }
        }

        /// The lookup `var` and `missing` share: the active data first, then
        /// any names an enclosing `rc.let` bound. Data wins, so a bound name
        /// can never mask a field the scope actually has, and a predicate with
        /// no `rc.let` around it resolves exactly as it did before bindings
        /// existed.
        ///
        /// The first path segment decides which of the two owns the whole
        /// lookup. Once the data has that segment, a missing descendant stays
        /// missing instead of being answered by a binding of the same name,
        /// which would otherwise pull a value out of an unrelated object.
        static func lookupInScope(_ vars: Scope, path: String) -> Value? {
            if let found = lookupVar(in: vars.current, path: path) {
                return found
            }
            guard !vars.bindings.isEmpty, !path.isEmpty else { return nil }
            let firstSegment = path.split(separator: ".", maxSplits: 1).first.map(String.init) ?? path
            guard lookupVar(in: vars.current, path: firstSegment) == nil else { return nil }
            return lookupPath(in: .object(vars.bindings), path: path)
        }

        /// Resolve `path` the way `var` does. Empty path returns the entire
        /// data scope; a resolving path returns its value (including explicit
        /// `.null`); a non-resolving path returns `nil`.
        static func lookupVar(in vars: Value, path: String) -> Value? {
            if path.isEmpty {
                return vars
            }
            return lookupPath(in: vars, path: path)
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
}
