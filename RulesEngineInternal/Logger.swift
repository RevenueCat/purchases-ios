//
//  Logger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Default log tag for `RulesEngineLogger`.
let rulesEngineLogTag = "[RulesEngine]"

/// Logging facade for the rules engine.
///
/// Two distinct channels:
/// - `warn` carries engine diagnostics (missing variables, unsupported
///   operators, type mismatches).
/// - `log` carries pass-through output from the JSON Logic `log` operator,
///   kept separate so hosts can route it independently (e.g. at debug level).
protocol RulesEngineLogger {

    func warn(_ message: String, tag: String)
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
