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
//  Created by RevenueCat.

import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable force_try

class SynchronizedUserDefaultsTests: TestCase {

    private var userDefaults: UserDefaults!
    private var synchronizedUserDefaults: SynchronizedUserDefaults!
    private let testKey = "com.revenuecat.test.deadlock.key"

    override func setUp() {
        super.setUp()
        self.userDefaults = UserDefaults(suiteName: "SynchronizedUserDefaultsTests")!
        self.userDefaults.removeObject(forKey: testKey)
        self.synchronizedUserDefaults = SynchronizedUserDefaults(userDefaults: self.userDefaults)
    }

    override func tearDown() {
        self.userDefaults.removeObject(forKey: testKey)
        self.userDefaults.removeSuite(named: "SynchronizedUserDefaultsTests")
        super.tearDown()
    }

    func testReadValue() {
        self.userDefaults.set("testValue", forKey: testKey)

        let value = self.synchronizedUserDefaults.read {
            $0.string(forKey: self.testKey)
        }

        expect(value) == "testValue"
    }

    func testWriteValue() {
        self.synchronizedUserDefaults.write {
            $0.set("writtenValue", forKey: self.testKey)
        }

        let value = self.userDefaults.string(forKey: testKey)
        expect(value) == "writtenValue"
    }

    /// Test for deadlock scenario described in:
    /// - https://github.com/RevenueCat/purchases-ios/issues/4137
    /// - https://github.com/RevenueCat/purchases-ios/issues/5729
    ///
    /// The deadlock occurs when:
    /// 1. Main thread tries to acquire the lock on SynchronizedUserDefaults for a read operation
    /// 2. A background thread is holding that lock (for a write operation) and posts
    ///    a `UserDefaults.didChangeNotification` to the main queue
    /// 3. The background thread waits for the notification to finish (due to how NotificationCenter works)
    /// 4. Deadlock: main thread waiting for lock, background thread waiting for main thread
    ///
    /// Test case credit: @nguyenhuy - https://github.com/RevenueCat/purchases-ios/issues/4137#issuecomment-2585672059
    func testNoDeadlockWhenWritingFromBackgroundAndReadingFromMain() {
        // Register a notification observer on the main queue that will be triggered
        // when UserDefaults changes.
        let notificationExpectation = expectation(description: "Notification received")
        notificationExpectation.assertForOverFulfill = false

        let observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            notificationExpectation.fulfill()
        }

        defer {
            NotificationCenter.default.removeObserver(observer)
        }

        // Write from background thread. Will post a notification to main queue
        DispatchQueue.global(qos: .userInteractive).async { [synchronizedUserDefaults, testKey] in
            synchronizedUserDefaults?.write {
                $0.set("value", forKey: testKey!)
            }
        }

        // Give the background write operation time to start and potentially trigger the notification.
        // The key issue is that the notification is posted synchronously but dispatched to main queue,
        // and the write operation may wait for it to complete (causing deadlock if main thread is blocked).
        Thread.sleep(forTimeInterval: 0.5)

        // Read from main thread. This deadlocks if the background thread is still holding the lock and
        // waiting for the notification to complete on main thread.
        let value = self.synchronizedUserDefaults.read {
            $0.string(forKey: self.testKey)
        }

        // If we get here without deadlock, the value should be set
        expect(value) == "value"

        wait(for: [notificationExpectation], timeout: 2.0)
    }

    func testConcurrentReadsDoNotDeadlock() {
        self.userDefaults.set("concurrentValue", forKey: testKey)

        let iterations = 100
        let expectation = expectation(description: "All reads complete")
        expectation.expectedFulfillmentCount = iterations

        for _ in 0..<iterations {
            DispatchQueue.global(qos: .userInteractive).async { [synchronizedUserDefaults, testKey] in
                _ = synchronizedUserDefaults?.read {
                    $0.string(forKey: testKey!)
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testConcurrentWritesDoNotDeadlock() {
        let iterations = 100
        let expectation = expectation(description: "All writes complete")
        expectation.expectedFulfillmentCount = iterations

        for iteration in 0..<iterations {
            DispatchQueue.global(qos: .userInteractive).async { [synchronizedUserDefaults, testKey] in
                synchronizedUserDefaults?.write {
                    $0.set("value\(iteration)", forKey: testKey!)
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testMixedConcurrentReadsAndWritesDoNotDeadlock() {
        let iterations = 100
        let expectation = expectation(description: "All operations complete")
        expectation.expectedFulfillmentCount = iterations * 2

        for iteration in 0..<iterations {
            DispatchQueue.global(qos: .userInteractive).async { [synchronizedUserDefaults, testKey] in
                synchronizedUserDefaults?.write {
                    $0.set("value\(iteration)", forKey: testKey!)
                }
                expectation.fulfill()
            }

            DispatchQueue.global(qos: .background).async { [synchronizedUserDefaults, testKey] in
                _ = synchronizedUserDefaults?.read {
                    $0.string(forKey: testKey!)
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

}

// swiftlint:enable force_try
