//
//  CapturingLogger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

@testable import RulesEngineInternal

/// Test-only logger that records warnings and `log`-channel messages
/// separately for later assertion.
final class CapturingLogger: RulesEngineLogger {

    private let lock = NSLock()
    private var capturedWarnings: [String] = []
    private var capturedLogs: [String] = []

    init() {}

    var warnings: [String] {
        lock.lock()
        defer { lock.unlock() }
        return capturedWarnings
    }

    var logs: [String] {
        lock.lock()
        defer { lock.unlock() }
        return capturedLogs
    }

    func warn(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        capturedWarnings.append(message)
    }

    func log(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        capturedLogs.append(message)
    }
}
