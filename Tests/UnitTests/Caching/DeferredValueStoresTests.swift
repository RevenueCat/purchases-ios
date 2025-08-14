//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeferredValueStoresTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/25.

@_spi(Internal) @testable import RevenueCat
import XCTest

final class DeferredValueStoresTests: TestCase {
    private let subject = KeyedDeferredValueStore<String, Int>()

    func test_getOrPut_getAndSetsByKey() async {
        let value = try? await subject.getOrPut(Task { 44 }, forKey: "X").value
        let value2 = try? await subject.getOrPut(Task { 42 }, forKey: "Y").value

        XCTAssertEqual(44, value)
        XCTAssertEqual(42, value2)
    }

    func test_getOrPut_retrievesStoredValue_fromHashedValueStore() async {
        let spy = Spy()
        _ = try? await subject.getOrPut(Task { 44 }, forKey: "X").value
        _ = await subject.getOrPut(
            Task {
                await spy.increment()
                return 1
            },
            forKey: "X"
        )
        let value = try? await subject.deferred["X"]?.value

        XCTAssertEqual(44, value)

        let wasCalled = await spy.wasInvoked
        XCTAssertFalse(wasCalled)
    }

    func test_getOrPut_protectsAgainstMultipleInvocations() async {
        let spy = Spy()
        _ = try? await subject.getOrPut(
            Task {
                await spy.increment()
                return 44
            },
            forKey: "X"
        ).value

        for _ in 0..<100 {
            let value = try? await subject.deferred["X"]?.value

            XCTAssertEqual(44, value)
            let callCount = await spy.count
            XCTAssertEqual(callCount, 1)
        }
    }

    func test_replaceValue_hashedValueStore() async {
        _ = try? await subject.getOrPut(Task { 44 }, forKey: "X").value
        let spy = Spy()
        _ = await subject.replaceValue(
            Task {
                await spy.increment()
                return 1
            },
            forKey: "X"
        )
        let value = try? await subject.deferred["X"]?.value

        XCTAssertEqual(1, value)
        let wasCalled = await spy.wasInvoked
        XCTAssertTrue(wasCalled)
    }

    func test_clear_removesValues() async throws {
        _ = await subject.getOrPut(Task { 44 }, forKey: "X")

        await subject.clear()

        let hash = try await subject.deferred["X"]?.value

        XCTAssertNil(hash)
    }

    func test_getOrPut_autoClears_failedTasks() async throws {
        do {
            _ = try await subject.getOrPut(Task { throw SampleError() }, forKey: "X").value
            XCTFail(#function)
        } catch {
            let value = await subject.deferred["X"]
            XCTAssertNil(value)
        }
    }

    func test_replaceValue_autoClears_failedTasks() async throws {
        do {
            _ = try await subject.replaceValue(Task { throw SampleError() }, forKey: "X").value
            XCTFail(#function)
        } catch {
            let value = await subject.deferred["X"]
            XCTAssertNil(value)
        }
    }

    struct SampleError: Error { }
}

actor Spy {
    var count = 0
    var wasInvoked: Bool = false

    init() { }

    func increment() async {
        if count == 0 {
            wasInvoked = true
        }
        count += 1
    }
}
