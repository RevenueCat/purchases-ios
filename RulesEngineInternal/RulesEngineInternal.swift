//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesEngineInternal.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Namespace for the RevenueCat rules engine.
enum RulesEngine {}

extension RulesEngine {

    /// Per-task override used by tests and scoped diagnostic callers.
    /// When `nil`, logging falls through to the module default.
    @TaskLocal static var scopedLogger: RulesEngineLogger?

    static var logger: RulesEngineLogger {
        scopedLogger ?? defaultLogger
    }

    private static let defaultLogger: RulesEngineLogger = PrintLogger()
}
