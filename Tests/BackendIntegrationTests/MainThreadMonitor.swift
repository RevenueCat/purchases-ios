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
        Logger.verbose("Initializing \(type(of: self)) with a threshold of \(Self.threshold.seconds) seconds")
    }

    deinit {
        Logger.verbose("Stopping \(type(of: self))")
    }

    func run() {
        guard !Self.debuggerIsAttached else {
            Logger.verbose("Debugger is attached, ignoring")
            return
        }

        self.queue.async { [weak self] in
            while self != nil {
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.main.async {
                    semaphore.signal()
                }

                let deadline = DispatchTime.now() + Self.threshold
                let result = semaphore.wait(timeout: deadline)

                precondition(
                    result != .timedOut,
                    "Main thread was blocked for more than \(Self.threshold.seconds) seconds"
                )
            }
        }
    }

    private static let threshold: DispatchTimeInterval = .seconds(1)

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
