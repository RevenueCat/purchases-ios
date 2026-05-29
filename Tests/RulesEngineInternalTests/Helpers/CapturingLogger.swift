//
//  CapturingLogger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

@testable import RulesEngineInternal

/// Test-only logger that records every warning it receives for later
/// assertion.
final class CapturingLogger: RulesEngineLogger {

    private let lock = NSLock()
    private var captured: [String] = []

    init() {}

    var warnings: [String] {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    func warn(_ message: String, tag: String) {
        lock.lock()
        defer { lock.unlock() }
        captured.append(message)
    }
}
