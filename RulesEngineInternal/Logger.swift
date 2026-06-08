//
//  Logger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Default log tag for `RulesEngineLogger`.
let rulesEngineLogTag = "[RulesEngine]"

/// Logging facade for the rules engine.
protocol RulesEngineLogger {

    /// Carries engine diagnostics (missing variables, unsupported
    /// operators, type mismatches).
    func warn(_ message: String, tag: String)

    /// Carries pass-through output from the JSON Logic `log` operator.
    func log(_ message: String, tag: String)
}

extension RulesEngineLogger {

    func warn(_ message: String) {
        warn(message, tag: rulesEngineLogTag)
    }

    func log(_ message: String) {
        log(message, tag: rulesEngineLogTag)
    }
}

/// Default logger for `RulesEngine.logger`.
struct PrintLogger: RulesEngineLogger {

    func warn(_ message: String, tag: String) {
        print("\(tag) \(message)")
    }

    func log(_ message: String, tag: String) {
        print("\(tag) \(message)")
    }
}
