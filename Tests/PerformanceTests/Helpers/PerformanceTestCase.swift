//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PerformanceTestCase.swift
//

import Foundation
@testable import RevenueCat
import XCTest

// swiftlint:disable:next xctestcase_superclass
class PerformanceTestCase: XCTestCase {

    private var previousLogLevel: LogLevel = .info

    override func setUp() async throws {
        try await super.setUp()
        self.previousLogLevel = Purchases.logLevel
        Purchases.logLevel = .error
    }

    override func tearDown() {
        Purchases.logLevel = self.previousLogLevel
        super.tearDown()
    }

    func measureMemory<Context>(
        workloadSHA256: String,
        prepare: @escaping () async throws -> Context,
        operation: @escaping (Context) async throws -> Void,
        validate: (Context) -> Void,
        testName: String = #function
    ) throws {
        let metadata = ["test": "\(type(of: self))/\(testName)", "sha256": workloadSHA256]
        let data = try JSONSerialization.data(withJSONObject: metadata, options: .sortedKeys)
        let metadataJSON = try XCTUnwrap(String(bytes: data, encoding: .utf8))
        print("PERFORMANCE_WORKLOAD \(metadataJSON)")
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        options.invocationOptions = [.manuallyStart, .manuallyStop]
        var failure: Error?
        self.measure(metrics: [XCTMemoryMetric(), XCTClockMetric()], options: options) {
            do {
                let context = try self.waitForCompletion(prepare)
                self.startMeasuring()
                do {
                    defer { self.stopMeasuring() }
                    try self.waitForCompletion { try await operation(context) }
                }
                validate(context)
            } catch {
                failure = error
            }
        }
        if let failure { throw failure }
    }

    private func waitForCompletion<Value>(_ operation: @escaping () async throws -> Value) throws -> Value {
        let completed = self.expectation(description: "Performance operation completed")
        let result = Atomic<Result<Value, Error>?>(nil)
        let task = Task {
            do {
                result.value = .success(try await operation())
            } catch {
                result.value = .failure(error)
            }
            completed.fulfill()
        }
        defer { task.cancel() }
        self.wait(for: [completed], timeout: 120)
        return try XCTUnwrap(result.value).get()
    }

}
