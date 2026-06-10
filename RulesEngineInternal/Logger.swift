//
//  Logger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Logging facade for the rules engine.
public protocol RulesEngineLogger: Sendable {

    /// Carries engine diagnostics (missing variables, unsupported
    /// operators, type mismatches).
    func warn(_ message: String)

    /// Carries pass-through output from the JSON Logic `log` operator.
    func log(_ message: String)
}

/// Default logger for `RulesEngine.logger`.
struct PrintLogger: RulesEngineLogger {

    func warn(_ message: String) {
        print(message)
    }

    func log(_ message: String) {
        print(message)
    }
}
