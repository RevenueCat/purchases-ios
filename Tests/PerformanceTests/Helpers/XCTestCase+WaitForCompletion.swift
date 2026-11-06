//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  XCTestCase+WaitForCompletion.swift
//

import Foundation
@testable import RevenueCat
import XCTest

extension XCTestCase {

    func waitForCompletion<Value>(_ operation: @escaping () async throws -> Value) throws -> Value {
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
