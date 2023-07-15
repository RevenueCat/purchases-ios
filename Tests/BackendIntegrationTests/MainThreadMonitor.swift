//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MainThreadMonitor.swift
//
//  Created by Nacho Soto on 5/1/23.

import Foundation
@testable import RevenueCat
import XCTest

final class MainThreadMonitor {

    private let queue: DispatchQueue

    init() {
        self.queue = .init(label: "com.revenuecat.MainThreadMonitor")
        Logger.verbose(Message.initializing_main_thread_monitor(threshold: Self.threshold))
    }

    deinit {
        Logger.verbose(Message.stopping)
    }

    func run() {
        guard !Self.debuggerIsAttached else {
            Logger.verbose(Message.ignoring)
            return
        }

        self.queue.async { [weak self] in
            while self != nil {
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.checkInterval) {
                    semaphore.signal()
                }

                let deadline = DispatchTime.now() + Self.threshold + Self.checkInterval
                let result = semaphore.wait(timeout: deadline)

                precondition(
                    result != .timedOut,
                    "Main thread was blocked for more than \(Self.threshold.seconds) seconds"
                )
            }
        }
    }

    /// Elapsed time before the thread is considered deadlocked.
    private static let threshold: DispatchTimeInterval = .seconds(30)
    /// How often a check is performed
    private static let checkInterval: DispatchTimeInterval = .seconds(3)

}

private extension MainThreadMonitor {

    // From https://stackoverflow.com/a/33177600/401024
    static var debuggerIsAttached: Bool {
        // Buffer for "sysctl(...)" call's result.
        var info = kinfo_proc()
        // Counts buffer's size in bytes (like C/C++'s `sizeof`).
        var size = MemoryLayout.stride(ofValue: info)
        // Tells we want info about own process.
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        // Call the API (and assert success).
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        // Finally, checks if debugger's flag is present yet.
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

}

// MARK: - logs

// swiftlint:disable identifier_name

private enum Message: LogMessage {

    case initializing_main_thread_monitor(threshold: DispatchTimeInterval)
    case stopping
    case ignoring

    var description: String {
        switch self {
        case let .initializing_main_thread_monitor(threshold):
            return "Initializing \(Self.name) with a threshold of \(threshold.seconds) seconds"

        case .stopping:
            return "Stopping \(Self.name)"

        case .ignoring:
            return "\(Self.name): debugger is attached, ignoring"
        }
    }

    var category: String { return Self.name }

    private static let name: String = "\(MainThreadMonitor.self)"

}
