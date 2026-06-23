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

}

class AsyncSignalTests: TestCase {

    func testWaitReturnsImmediatelyWhenAlreadySignaled() async {
        let signal = AsyncSignal()
        signal.signal()

        await signal.wait()
    }

    func testWaitResumesAfterSignal() async {
        let signal = AsyncSignal()
        let resumed: Atomic<Bool> = false

        let waiter = Task {
            await signal.wait()
            resumed.value = true
        }

        // The waiter should still be suspended before the signal.
        expect(resumed.value) == false

        signal.signal()
        await waiter.value

        expect(resumed.value) == true
    }

    func testSignalResumesAllWaiters() async {
        let signal = AsyncSignal()
        let resumedCount: Atomic<Int> = .init(0)

        let waiters = (0..<5).map { _ in
            Task {
                await signal.wait()
                resumedCount.modify { $0 += 1 }
            }
        }

        signal.signal()
        for waiter in waiters {
            await waiter.value
        }

        expect(resumedCount.value) == 5
    }

    func testMultipleSignalsAreNoOps() async {
        let signal = AsyncSignal()
        signal.signal()
        signal.signal()

        await signal.wait()
        await signal.wait()
    }

}
