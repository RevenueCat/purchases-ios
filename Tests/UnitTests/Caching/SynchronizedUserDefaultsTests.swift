//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SynchronizedUserDefaultsTests.swift
//
//  Created by Jacob Zivan Rakidzich on 12/8/25.

import Foundation
@testable import RevenueCat
import XCTest

class SynchronizedUserDefaultsTests: TestCase {

    private var userDefaults: UserDefaults!
    private var synchronizedUserDefaults: SynchronizedUserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        userDefaults = UserDefaults(suiteName: "SynchronizedUserDefaultsTests")!
        userDefaults.removePersistentDomain(forName: "SynchronizedUserDefaultsTests")
        synchronizedUserDefaults = SynchronizedUserDefaults(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "SynchronizedUserDefaultsTests")
        userDefaults = nil
        synchronizedUserDefaults = nil
        super.tearDown()
    }

    // MARK: - Deadlock Tests

    func testDeadlockDoesNotOccur() {
        // Main Queue listener is essential for the deadlock to occur
        NotificationCenter.default
            .addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: OperationQueue.main
            ) { _ in }

        DispatchQueue.global(qos: .userInteractive).async { [synchronizedUserDefaults] in
            synchronizedUserDefaults.write {
                $0.set("value", forKey: "key")
            }
        }

        // Suspend to give the above background write operation time
        // to perform and trigger a did change notification on the main queue
        Thread.sleep(forTimeInterval: 0.5)

        _ = synchronizedUserDefaults.read {
            $0.string(forKey: "key")
        }
    }

    func testDeadlockDoesNotOccurWithCustomQueue() {
        // Custom queue listener to test deadlock on non-main queues
        let customQueue = OperationQueue()
        customQueue.name = "com.revenuecat.test.customQueue"

        NotificationCenter.default
            .addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: customQueue
            ) { _ in }

        DispatchQueue.global(qos: .userInteractive).async { [synchronizedUserDefaults] in
            synchronizedUserDefaults!.write {
                $0.set("value", forKey: "customQueueKey")
            }
        }

        // Suspend to give the above background write operation time
        // to perform and trigger a did change notification on the queue
        Thread.sleep(forTimeInterval: 0.5)

        // Verify read also works after write
        let result = synchronizedUserDefaults.read {
            $0.string(forKey: "customQueueKey")
        }

        XCTAssertEqual(result, "value")
    }

    func testDeadlockDoesNotOccurWithMultipleQueueListeners() {
        // Multiple queue listeners to stress test potential deadlock scenarios
        let queue1 = OperationQueue()
        queue1.name = "com.revenuecat.test.queue1"
        let queue2 = OperationQueue()
        queue2.name = "com.revenuecat.test.queue2"

        NotificationCenter.default
            .addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: OperationQueue.main
            ) { _ in }

        NotificationCenter.default
            .addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: queue1
            ) { _ in }

        NotificationCenter.default
            .addObserver(
                forName: UserDefaults.didChangeNotification,
                object: nil,
                queue: queue2
            ) { _ in }

        let iterations = 10
        let writeExpectation = expectation(description: "All writes complete")
        writeExpectation.expectedFulfillmentCount = iterations

        for iteration in 0..<iterations {
            DispatchQueue.global().async { [synchronizedUserDefaults] in
                synchronizedUserDefaults!.write {
                    $0.set("value\(iteration)", forKey: "multiQueueKey\(iteration)")
                }
                writeExpectation.fulfill()
            }
        }

        wait(for: [writeExpectation], timeout: 5.0)

        // Verify reads work correctly
        for iteration in 0..<iterations {
            let result = synchronizedUserDefaults.read {
                $0.string(forKey: "multiQueueKey\(iteration)")
            }
            XCTAssertEqual(result, "value\(iteration)")
        }
    }

    // MARK: - Basic Read Tests

    func testReadReturnsValueFromUserDefaults() {
        let key = "testReadKey"
        let expectedValue = "testValue"
        userDefaults.set(expectedValue, forKey: key)

        let result = synchronizedUserDefaults.read { defaults in
            defaults.string(forKey: key)
        }

        XCTAssertEqual(result, expectedValue)
    }

    func testReadReturnsNilForMissingKey() {
        let result = synchronizedUserDefaults.read { defaults in
            defaults.string(forKey: "nonExistentKey")
        }

        XCTAssertNil(result)
    }

    func testReadReturnsIntegerValue() {
        let key = "integerKey"
        let expectedValue = 42
        userDefaults.set(expectedValue, forKey: key)

        let result = synchronizedUserDefaults.read { defaults in
            defaults.integer(forKey: key)
        }

        XCTAssertEqual(result, expectedValue)
    }

    func testReadReturnsBoolValue() {
        let key = "boolKey"
        userDefaults.set(true, forKey: key)

        let result = synchronizedUserDefaults.read { defaults in
            defaults.bool(forKey: key)
        }

        XCTAssertTrue(result)
    }

    func testReadReturnsDataValue() {
        let key = "dataKey"
        let expectedValue = "test data".data(using: .utf8)!
        userDefaults.set(expectedValue, forKey: key)

        let result = synchronizedUserDefaults.read { defaults in
            defaults.data(forKey: key)
        }

        XCTAssertEqual(result, expectedValue)
    }

    // MARK: - Basic Write Tests

    func testWriteSetsStringValue() {
        let key = "writeStringKey"
        let value = "written value"

        synchronizedUserDefaults.write { defaults in
            defaults.set(value, forKey: key)
        }

        XCTAssertEqual(userDefaults.string(forKey: key), value)
    }

    func testWriteSetsIntegerValue() {
        let key = "writeIntegerKey"
        let value = 123

        synchronizedUserDefaults.write { defaults in
            defaults.set(value, forKey: key)
        }

        XCTAssertEqual(userDefaults.integer(forKey: key), value)
    }

    func testWriteSetsBoolValue() {
        let key = "writeBoolKey"

        synchronizedUserDefaults.write { defaults in
            defaults.set(true, forKey: key)
        }

        XCTAssertTrue(userDefaults.bool(forKey: key))
    }

    func testWriteRemovesValue() {
        let key = "removeKey"
        userDefaults.set("initialValue", forKey: key)

        synchronizedUserDefaults.write { defaults in
            defaults.removeObject(forKey: key)
        }

        XCTAssertNil(userDefaults.string(forKey: key))
    }

    // MARK: - Write Then Read Tests

    func testWriteThenReadReturnsWrittenValue() {
        let key = "writeThenReadKey"
        let value = "written then read"

        synchronizedUserDefaults.write { defaults in
            defaults.set(value, forKey: key)
        }

        let result = synchronizedUserDefaults.read { defaults in
            defaults.string(forKey: key)
        }

        XCTAssertEqual(result, value)
    }

    // MARK: - Throwing Action Tests

    func testReadRethrowsError() {
        enum TestError: Error { case testError }

        XCTAssertThrowsError(try synchronizedUserDefaults.read { _ in
            throw TestError.testError
        }) { error in
            XCTAssertTrue(error is TestError)
        }
    }

    func testWriteRethrowsError() {
        enum TestError: Error { case testError }

        XCTAssertThrowsError(try synchronizedUserDefaults.write { _ in
            throw TestError.testError
        }) { error in
            XCTAssertTrue(error is TestError)
        }
    }

    // MARK: - Re-entrant Operation Tests

    func testReentrantReadWithinRead() {
        let key = "reentrantKey"
        userDefaults.set("value", forKey: key)

        let result = synchronizedUserDefaults.read { [synchronizedUserDefaults] _ in
            // Nested read should not deadlock due to recursive lock
            let innerResult = synchronizedUserDefaults!.read { innerDefaults in
                innerDefaults.string(forKey: key)
            }
            return innerResult
        }

        XCTAssertEqual(result, "value")
    }

    func testReentrantWriteWithinWrite() {
        let key1 = "reentrantKey1"
        let key2 = "reentrantKey2"

        synchronizedUserDefaults.write { [synchronizedUserDefaults] defaults in
            defaults.set("value1", forKey: key1)
            // Nested write should not deadlock due to recursive lock
            synchronizedUserDefaults!.write { innerDefaults in
                innerDefaults.set("value2", forKey: key2)
            }
        }

        XCTAssertEqual(userDefaults.string(forKey: key1), "value1")
        XCTAssertEqual(userDefaults.string(forKey: key2), "value2")
    }

    func testReentrantReadWithinWrite() {
        let key = "reentrantReadWriteKey"
        userDefaults.set("existingValue", forKey: key)

        synchronizedUserDefaults.write { [synchronizedUserDefaults] defaults in
            let existingValue = synchronizedUserDefaults!.read { innerDefaults in
                innerDefaults.string(forKey: key)
            }
            defaults.set((existingValue ?? "") + "_appended", forKey: key)
        }

        XCTAssertEqual(userDefaults.string(forKey: key), "existingValue_appended")
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentReadsDoNotCrash() {
        let key = "concurrentReadKey"
        userDefaults.set("concurrent value", forKey: key)

        let iterations = 100
        let expectation = self.expectation(description: "All reads complete")
        expectation.expectedFulfillmentCount = iterations

        for _ in 0..<iterations {
            DispatchQueue.global().async { [synchronizedUserDefaults] in
                _ = synchronizedUserDefaults!.read { defaults in
                    defaults.string(forKey: key)
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testConcurrentWritesDoNotCrash() {
        let iterations = 100
        let expectation = self.expectation(description: "All writes complete")
        expectation.expectedFulfillmentCount = iterations

        for iteration in 0..<iterations {
            DispatchQueue.global().async { [synchronizedUserDefaults] in
                synchronizedUserDefaults!.write { defaults in
                    defaults.set("value\(iteration)", forKey: "concurrentWriteKey\(iteration)")
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testConcurrentReadsAndWritesDoNotCrash() {
        let key = "concurrentReadWriteKey"
        let iterations = 100
        let expectation = self.expectation(description: "All operations complete")
        expectation.expectedFulfillmentCount = iterations * 2

        for iteration in 0..<iterations {
            DispatchQueue.global().async { [synchronizedUserDefaults] in
                synchronizedUserDefaults!.write { defaults in
                    defaults.set("value\(iteration)", forKey: key)
                }
                expectation.fulfill()
            }

            DispatchQueue.global().async { [synchronizedUserDefaults] in
                _ = synchronizedUserDefaults!.read { defaults in
                    defaults.string(forKey: key)
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testConcurrentWritesToSameKeyMaintainsConsistency() {
        let key = "sameKeyWriteKey"
        let iterations = 100
        let expectation = self.expectation(description: "All writes complete")
        expectation.expectedFulfillmentCount = iterations

        for iteration in 0..<iterations {
            DispatchQueue.global().async { [synchronizedUserDefaults] in
                synchronizedUserDefaults!.write { defaults in
                    defaults.set(iteration, forKey: key)
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)

        // The final value should be one of the written values (0 to iterations-1)
        let finalValue = synchronizedUserDefaults.read { defaults in
            defaults.integer(forKey: key)
        }
        XCTAssertTrue(finalValue >= 0 && finalValue < iterations)
    }
}
