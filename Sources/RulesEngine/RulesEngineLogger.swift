//
//  Logger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Logging facade for the rules engine.
protocol RulesEngineLogger: Sendable {

    /// Carries engine diagnostics for conditions the evaluator recovers from,
    /// such as ignored extra operator arguments. Conditions that make a rule
    /// unanswerable surface as `EvaluationError` instead.
    func warn(_ message: String)

    /// Carries pass-through output from the JSON Logic `log` operator.
    func log(_ message: String)
}

extension RulesEngine {

    /// Default logger for `RulesEngine.logger`.
    struct PrintLogger: RulesEngineLogger {

        func warn(_ message: String) {
            print(message)
        }

        func log(_ message: String) {
            print(message)
        }
    }
}
