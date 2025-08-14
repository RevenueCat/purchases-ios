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

@testable import RevenueCat
import XCTest

final class DeferredValueStoresTests: TestCase {
    private let subject = KeyedDeferredValueStore<String, Int>()
    var keyedWasCalled = false

    func test_getOrPut_getAndSetsByKey() async {
        let value = try? await subject.getOrPut(Task { 44 }, forKey: "X").value
        let value2 = try? await subject.getOrPut(Task { 42 }, forKey: "Y").value

        XCTAssertEqual(44, value)
        XCTAssertEqual(42, value2)
    }

    func test_getOrPut_retrievesStoredValue_fromHashedValueStore() async {
        _ = try? await subject.getOrPut(Task { 44 }, forKey: "X").value
        var keyedWasCalled = false
        _ = await subject.getOrPut(
            Task { @MainActor in
                keyedWasCalled = true
                return 1
            },
            forKey: "X"
        )
        let value = try? await subject.deferred["X"]?.value
        await yield()
        XCTAssertEqual(44, value)
        XCTAssertFalse(keyedWasCalled)
    }

    func test_getOrPut_protectsAgainstMultipleInvocations() async {
        var callCount = 0

        _ = try? await subject.getOrPut(
            Task { @MainActor in
                callCount += 1
                return 44
            },
            forKey: "X"
        ).value

        for _ in 0..<100 {
            let value = try? await subject.deferred["X"]?.value
            await yield()
            XCTAssertEqual(44, value)
            XCTAssertEqual(callCount, 1)
        }
    }

    func test_replaceValue_hashedValueStore() async {
        _ = try? await subject.getOrPut(Task { 44 }, forKey: "X").value
        var keyedWasCalled = false
        _ = await subject.replaceValue(
            Task { @MainActor in
                keyedWasCalled = true
                return 1
            },
            forKey: "X"
        )
        let value = try? await subject.deferred["X"]?.value
        await yield()
        XCTAssertEqual(1, value)
        XCTAssertTrue(keyedWasCalled)
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
