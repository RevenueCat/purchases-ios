//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesEngineEvaluator.swift
//
//  Created by Antonio Pallares on 11/6/26.
//

import Foundation

#if compiler(>=6)
internal import RulesEngineInternal
#else
@_implementationOnly import RulesEngineInternal
#endif

enum RulesEngineEvaluator {

    private static let state = RulesEngineEvaluatorState()

    static func evaluate(
        predicate: String,
        variables: [String: Value]
    ) -> Result<Bool, RulesEngine.EvaluationError> {
        Self.installLoggerIfNeeded()

        return RulesEngine.evaluate(predicate: predicate, variables: variables)
    }

    private static func installLoggerIfNeeded() {
        guard Self.state.markInstalledIfNeeded() else { return }

        RulesEngine.setLogger(RulesEngineLoggerAdapter())
    }

}

private final class RulesEngineEvaluatorState: @unchecked Sendable {

    private let lock = NSLock()
    private var installed = false

    func markInstalledIfNeeded() -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }

        guard !self.installed else { return false }

        self.installed = true
        return true
    }

}

private struct RulesEngineLoggerAdapter: RulesEngineLogger {

    func warn(_ message: String) {
        Logger.warning(Strings.rules_engine_warning(message))
    }

    func log(_ message: String) {
        Logger.debug(Strings.rules_engine_log(message))
    }

}
