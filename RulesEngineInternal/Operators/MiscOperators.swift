//
//  MiscOperators.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Miscellaneous operators: `log`.
enum MiscOperators {

    /// `{"log": value}` — evaluates its single argument, emits it through the
    /// dedicated `log` channel of `RulesEngine.logger`, and returns it unchanged
    /// (identity passthrough).
    /// Mirrors json-logic-js `function(a){ console.log(a); return a; }`: a
    /// debug aid that never affects a rule's outcome. A missing argument is
    /// `undefined` (logged as `"undefined"`); operands beyond the first are
    /// ignored.
    static func opLog(args: Value, vars: Value) throws -> Value {
        let value = try Operators.evalArgs(args, vars: vars).first ?? .undefined
        RulesEngine.logger.log(jsString(value))
        return value
    }
}
