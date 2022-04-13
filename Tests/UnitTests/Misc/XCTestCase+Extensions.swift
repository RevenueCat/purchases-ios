//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  XCTestCase+Extensions.swift
//
//  Created by Andrés Boedo on 9/16/21.

import Foundation
@testable import RevenueCat
import XCTest

extension XCTestCase {

    func expectFatalError(
        expectedMessage: String,
        testcase: @escaping () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = self.expectation(description: "expectingFatalError")
        var fatalErrorReceived = false
        var assertionMessage: String?

        FatalErrorUtil.replaceFatalError { message, _, _ in
            fatalErrorReceived = true
            assertionMessage = message
            expectation.fulfill()
            self.unreachable()
        }

        DispatchQueue.global(qos: .userInitiated).async(execute: testcase)

        waitForExpectations(timeout: 2) { _ in
            XCTAssert(fatalErrorReceived, "fatalError wasn't received", file: file, line: line)
            XCTAssertEqual(assertionMessage, expectedMessage, file: file, line: line)

            FatalErrorUtil.restoreFatalError()
        }
    }

    func expectNoFatalError(
        testcase: @escaping () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = self.expectation(description: "expectingNoFatalError")
        var fatalErrorReceived = false

        FatalErrorUtil.replaceFatalError { _, _, _ in
            fatalErrorReceived = true
            self.unreachable()
        }

        DispatchQueue.global(qos: .userInitiated).async {
            testcase()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2) { _ in
            XCTAssert(!fatalErrorReceived, "fatalError was received", file: file, line: line)
            FatalErrorUtil.restoreFatalError()
        }
    }

}

/// Similar to `XCTUnrap` but it allows an `async` closure.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
func XCTAsyncUnwrap<T>(
    _ expression: @autoclosure () async throws -> T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async throws -> T {
    let value = try await expression()

    return try XCTUnwrap(
        value,
        message(),
        file: file,
        line: line
    )
}

private extension XCTestCase {

    func unreachable() -> Never {
        repeat {
            RunLoop.current.run()
        } while (true)
    }

}
