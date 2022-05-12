//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AtomicTests.swift
//
//  Created by Nacho Soto on 11/25/21.

import Nimble
import XCTest

@testable import RevenueCat

class AtomicTests: TestCase {
    func testInitialValue() {
        let value = Int.random(in: 0..<100)
        let atomic = Atomic(value)

        expect(atomic.value) == value
    }

    func testModify() {
        let atomic = Atomic(10)
        atomic.modify { $0 += 10 }

        expect(atomic.value) == 20
    }

    func testModifyReturnsResult() {
        let atomic = Atomic(10)
        let result: Bool = atomic.modify { $0 += 10; return false }

        expect(result) == false
    }

    func testWithValue() {
        let atomic = Atomic(10)
        let result: Int = atomic.withValue { $0 + 10 }

        expect(result) == 20
    }

}
