//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesEngineLoggerBridge.swift
//
//  Created by Rick van der Linden on 8/13/26.
//

import Foundation

/// Routes rules-engine diagnostics through the SDK logger while keeping the engine independently extractable.
struct RulesEngineLoggerBridge: RulesEngineLogger {

    func warn(_ message: String) {
        Logger.debug(RulesEngineLogMessage(description: "Rules engine: \(message)"))
    }

    func log(_ message: String) {
        Logger.verbose(RulesEngineLogMessage(description: "Rules engine: \(message)"))
    }

}

private struct RulesEngineLogMessage: LogMessage {

    let description: String
    let category = "rules_engine"

}
