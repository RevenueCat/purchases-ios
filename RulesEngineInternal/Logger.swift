//
//  Logger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Default log tag for `RulesEngineLogger.warn`.
let rulesEngineLogTag = "[RulesEngine]"

/// Logging facade for the rules engine.
///
/// Diagnostic warnings are routed through `RulesEngine.logger`.
protocol RulesEngineLogger {

    func warn(_ message: String, tag: String)
}

extension RulesEngineLogger {

    func warn(_ message: String) {
        warn(message, tag: rulesEngineLogTag)
    }
}

/// Default logger for `RulesEngine.logger`.
struct PrintLogger: RulesEngineLogger {

    func warn(_ message: String, tag: String) {
        print("\(tag) \(message)")
    }
}
