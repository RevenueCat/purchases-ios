//
//  Logger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Module-internal logging facade.
///
/// Intentionally NOT exposed via the public API in this slice. It is shaped
/// so that a future foreign logger (injected from the host SDK) can be
/// adapted to the same `RulesEngineLogger` protocol without changing any
/// caller.
///
/// Default behaviour during development is noisy (`PrintLogger`); the
/// production default will be revisited once the engine is wired up to the
/// rest of the SDK.
protocol RulesEngineLogger {

    func warn(_ message: String)
}

/// Stop-gap default logger. The native SDK injects its own adapter at
/// integration time, so this exists only to avoid an optional logger
/// type during development.
struct PrintLogger: RulesEngineLogger {

    func warn(_ message: String) {
        print("[RulesEngine] \(message)")
    }
}
