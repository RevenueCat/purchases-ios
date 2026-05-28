//
//  Logger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Logging facade for the rules engine.
///
/// Diagnostic warnings are routed through `RulesEngine.logger`.
protocol RulesEngineLogger {

    func warn(_ message: String)
}

/// Default logger for `RulesEngine.logger`.
struct PrintLogger: RulesEngineLogger {

    func warn(_ message: String) {
        print("[RulesEngine] \(message)")
    }
}
