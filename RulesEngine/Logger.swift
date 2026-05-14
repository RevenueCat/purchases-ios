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
internal protocol RulesEngineLogger {

    func warn(_ message: String)
}

/// Default logger used by the in-module callers: writes warnings to stderr
/// via `print(... to: &stderr)` so warnings don't get lost in release-mode
/// log filters that ignore plain `print`.
internal struct PrintLogger: RulesEngineLogger {

    init() {}

    func warn(_ message: String) {
        var stderr = FileHandleOutputStream(handle: .standardError)
        print("[RulesEngine] \(message)", to: &stderr)
    }
}

/// Test-only logger that captures messages for assertion. Lives in the
/// production module (rather than under `Tests/`) so non-test callers can
/// reference it from internal helpers without an extra link step. Marked
/// `final` since there is no reason to subclass it.
internal final class CapturingLogger: RulesEngineLogger {

    private let lock = NSLock()
    private var captured: [String] = []

    init() {}

    var warnings: [String] {
        lock.lock()
        defer { lock.unlock() }
        return captured
    }

    func warn(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        captured.append(message)
    }
}

/// Adapts a `FileHandle` to `TextOutputStream` so we can write to stderr via
/// the standard `print(... to:)` API. Only used by `PrintLogger`.
private struct FileHandleOutputStream: TextOutputStream {

    let handle: FileHandle

    mutating func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        handle.write(data)
    }
}
