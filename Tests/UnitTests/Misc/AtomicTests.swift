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

import Foundation
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

    func testGetAndSet() {
        let atomic = Atomic(false)
        let oldValue = atomic.getAndSet(true)

        expect(oldValue) == false
        expect(atomic.value) == true
    }

    func testWithValue() {
        let atomic = Atomic(10)
        let result: Int = atomic.withValue { $0 + 10 }

        expect(result) == 20
    }

    func testModifyValueDirectly() {
        let atomic: Atomic<[String: Int]> = .init([:])

        atomic.value = ["0": 0]
        expect(atomic.value) == ["0": 0]

        atomic.value += ["1": 1, "2": 2]
        expect(atomic.value) == ["0": 0, "1": 1, "2": 2]
    }

    func testRecursiveUnrelatedAtomics() {
        let atomic1: Atomic<Bool> = false
        let atomic2: Atomic<Bool> = false

        atomic1.modify {
            $0 = !atomic2.value
        }

        expect(atomic1.value) == true
        expect(atomic2.value) == false
    }

    func testIncrementIncreasesValueByDefaultAmount() {
        let atomic = Atomic(5)

        let newValue = atomic.increment()

        expect(newValue) == 6
        expect(atomic.value) == 6
    }

    func testIncrementByCustomAmount() {
        let atomic = Atomic(5)

        let newValue = atomic.increment(by: 3)

        expect(newValue) == 8
        expect(atomic.value) == 8
    }

    func testDecrementDecreasesValueByDefaultAmount() {
        let atomic = Atomic(5)

        let newValue = atomic.decrement()

        expect(newValue) == 4
        expect(atomic.value) == 4
    }

    func testDecrementByCustomAmount() {
        let atomic = Atomic(5)

        let newValue = atomic.decrement(by: 2)

        expect(newValue) == 3
        expect(atomic.value) == 3
    }

    func testConcurrentIncrementsProduceCorrectTotal() {
        let atomic = Atomic(0)
        let iterations = 1_000

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            atomic.increment()
        }

        expect(atomic.value) == iterations
    }

    func testConcurrentIncrementsAndDecrementsAreAtomic() {
        let atomic = Atomic(0)
        let iterations = 1_000

        // Equal numbers of increments and decrements should leave the value unchanged,
        // regardless of the order in which the concurrent operations complete.
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            if index % 2 == 0 {
                atomic.increment()
            } else {
                atomic.decrement()
            }
        }

        expect(atomic.value) == 0
    }

}
