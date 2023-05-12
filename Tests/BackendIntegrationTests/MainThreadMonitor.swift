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
