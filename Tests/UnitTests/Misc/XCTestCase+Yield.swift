//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  XCTestCase+Yield.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Foundation
import XCTest

extension XCTestCase {

    /// A helper method that will reliably cause the operating system to pick up another asynchronous task
    ///
    /// > Important: This works by awaiting alow priority task yielding to a higher priority task.
    /// > This will not be reliable when attempting to pick up low priority tasks.
    func yield() async {
        await Task(priority: .low) {
            await Task.yield()
        }.value
    }
}
