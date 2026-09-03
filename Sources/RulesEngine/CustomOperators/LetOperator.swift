//
//  LetOperator.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Name used in this operator's error messages.
private let operatorName = "rc.let"

extension RulesEngine {

    /// `rc.let` — binds names that stay readable inside iteration.
    enum LetOperator {

        /// `{"rc.let": [{"name": expression, ...}, body]}` — evaluates `body`
        /// with each name available to `var`.
        ///
        /// Iteration replaces the whole scope with the current item, so a
        /// predicate nested inside `some` or `reduce` cannot otherwise reach a
        /// value from the enclosing level. Binding it first is what makes
        /// comparing an item against something outside the loop expressible.
        ///
        /// `var` reads the active data first and falls back to these names, so
        /// a binding never masks a field the data actually has.
        ///
        /// The declarations are a literal object, not an evaluated one: a
        /// single-key object anywhere else in a predicate is an operator call,
        /// which is why the argument is never evaluated as a whole. Every
        /// declared expression is evaluated in the scope enclosing the
        /// `rc.let`, so bindings cannot see each other and their order carries
        /// no meaning; nest a second `rc.let` to build one from another.
        ///
        /// Names must be non-empty and free of `.`, since a dotted name would
        /// be unreachable behind path traversal. Anything else, including a
        /// non-object declaration list or the wrong argument count, throws
        /// `EvaluationError.typeMismatch`.
        static func opLet(args: Value, vars: Scope) throws -> Value {
            let raw = Operators.argsAsList(args)

            try Operators.checkArity(raw.count, allowed: [2], operatorName: operatorName)

            guard case .object(let declarations) = raw[0] else {
                throw EvaluationError.typeMismatch(
                    message: "operator '\(operatorName)' expected an object of bindings, "
                        + "got \(raw[0])"
                )
            }

            var bindings: [String: Value] = [:]
            // Sorted so that a predicate with two invalid names fails the same
            // way on both engines.
            for name in declarations.keys.sorted() {
                guard !name.isEmpty, !name.contains(".") else {
                    throw EvaluationError.typeMismatch(
                        message: "operator '\(operatorName)' expected a binding name that is "
                            + "non-empty and free of '.', got '\(name)'"
                    )
                }
                bindings[name] = try Evaluator.evaluateValue(declarations[name] ?? .null, vars: vars)
            }

            return try Evaluator.evaluateValue(raw[1], vars: vars.binding(bindings))
        }
    }
}
