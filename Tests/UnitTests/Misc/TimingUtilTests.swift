//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TimingUtilTests.swift
//
//  Created by Nacho Soto on 11/15/22.

import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class TimingUtilAsyncTests: TestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()
    }

    func testMeasureNonThrowingBlockReturnsValueAndDuration() async {
        let expectedResult = Int.random(in: 0..<1000)
        let sleepDuration: DispatchTimeInterval = .milliseconds(10)

        let (result, time) = await TimingUtil.measure { () -> Int in
            try? await Task.sleep(nanoseconds: UInt64(sleepDuration.nanoseconds))

            return expectedResult
        }

        expect(result) == expectedResult
        expect(time) > 0
        expect(time).to(beCloseTo(sleepDuration.seconds, within: 0.01))
    }

    func testMeasureThrowsError() async {
        let expectedError: ErrorCode = .storeProblemError

        do {
            _ = try await TimingUtil.measure {
                throw expectedError
            }

            fail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }

    func testMeasureAndLogWithResultDoesNotLogIfLowerThanThreshold() async {
        let logger = TestLogHandler()

        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .milliseconds(10)
        let sleepDuration = threshold + .milliseconds(-5)

        let result = await TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                                             message: "Too slow") { () -> Int in
            try? await Task.sleep(nanoseconds: UInt64(sleepDuration.nanoseconds))

            return expectedResult
        }

        expect(result) == expectedResult
        expect(logger.messages).to(beEmpty())
    }

    func testMeasureAndLogWithResult() async {
        let logger = TestLogHandler()

        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .milliseconds(10)
        let sleepDuration = threshold + .milliseconds(10)

        let message = "Computation took too long"
        let level: LogLevel = .info

        let result = await TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                                             message: message,
                                                             level: level) { () -> Int in
            try? await Task.sleep(nanoseconds: UInt64(sleepDuration.nanoseconds))

            return expectedResult
        }

        expect(result) == expectedResult

        // Expected: 🍎⚠️ Computation took too long (0.02 seconds)
        logger.verifyMessageWasLogged(
            String(format: "%@ %@ (%.2f seconds)",
                   LogIntent.appleWarning.prefix,
                   message,
                   sleepDuration.seconds),
            level: level
        )
    }

    func testMeasureAndLogThrowsError() async {
        let logger = TestLogHandler()

        let expectedError: ErrorCode = .storeProblemError

        do {
            _ = try await TimingUtil.measureAndLogIfTooSlow(threshold: 0.001,
                                                            message: "Too slow") {
                throw expectedError
            }

            fail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError))
        }

        expect(logger.messages).to(beEmpty())
    }

    func testMeasureSyncAndLogDoesNotLogIfLowerThanThreshold() {
        let logger = TestLogHandler()

        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .milliseconds(10)
        let sleepDuration = threshold + .milliseconds(-5)

        let result: Int = TimingUtil.measureSyncAndLogIfTooSlow(threshold: threshold.seconds,
                                                                message: "Too slow") {
            Thread.sleep(forTimeInterval: sleepDuration.seconds)

            return expectedResult
        }

        expect(result) == expectedResult
        expect(logger.messages).to(beEmpty())
    }

    func testMeasureSyncAndLogThrowsError() {
        let logger = TestLogHandler()

        let expectedError: ErrorCode = .storeProblemError

        do {
            _ = try TimingUtil.measureSyncAndLogIfTooSlow(threshold: 0.001,
                                                          message: "Too slow") {
                throw expectedError
            }

            fail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError))
        }

        expect(logger.messages).to(beEmpty())
    }

    func testMeasureSyncAndLogWithResult() {
        let logger = TestLogHandler()

        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .milliseconds(10)
        let sleepDuration = threshold + .milliseconds(10)

        let message = "Computation took too long"
        let level: LogLevel = .info

        let result = TimingUtil.measureSyncAndLogIfTooSlow(threshold: threshold.seconds,
                                                           message: message,
                                                           level: level) { () -> Int in
            Thread.sleep(forTimeInterval: sleepDuration.seconds)

            return expectedResult
        }

        expect(result) == expectedResult

        // Expected: 🍎⚠️ Computation took too long (0.02 seconds)
        logger.verifyMessageWasLogged(
            String(format: "%@ %@ (%.2f seconds)",
                   LogIntent.appleWarning.prefix,
                   message,
                   sleepDuration.seconds),
            level: level
        )
    }
}

class TimingUtilCompletionBlockTests: TestCase {

    func testMeasureWithCompletionBlock() {
        let expectedResult: Int = .random(in: 0..<1000)
        let sleepDuration: DispatchTimeInterval = .milliseconds(10)

        var result: Int?
        var duration: TimingUtil.Duration?

        TimingUtil.measure { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + sleepDuration) {
                Self.asynchronousWork(expectedResult, completion)
            }
        } result: { value, time in
            result = value
            duration = time
        }

        expect(result).toEventuallyNot(beNil())
        expect(result) == expectedResult
        expect(duration) > 0
        expect(duration).to(beCloseTo(sleepDuration.seconds, within: 0.01))
    }

    func testMeasureAndLogDoesNotLogIfLowerThanThreshold() {
        let logger = TestLogHandler()

        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .milliseconds(10)
        let sleepDuration = threshold + .milliseconds(-5)

        var result: Int?

        TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                          message: "Too slow") { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + sleepDuration) {
                Self.asynchronousWork(expectedResult, completion)
            }
        } result: { value in
            result = value
        }

        expect(result).toEventuallyNot(beNil())
        expect(result) == expectedResult
        expect(logger.messages).to(beEmpty())
    }

    func testMeasureAndLogWithResult() {
        let logger = TestLogHandler()

        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .milliseconds(10)
        let sleepDuration = threshold + .milliseconds(10)

        let message = "Computation took too long"
        let level: LogLevel = .info

        var result: Int?

        TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                          message: message,
                                          level: level) { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + sleepDuration) {
                Self.asynchronousWork(expectedResult, completion)
            }
        } result: { value in
            result = value
        }

        expect(result).toEventuallyNot(beNil())
        expect(result) == expectedResult

        logger.verifyMessageWasLogged(
            String(format: "%@ %@ (%.2f seconds)",
                   LogIntent.appleWarning.prefix,
                   message,
                   sleepDuration.seconds),
            level: level
        )
    }

    private static func asynchronousWork(_ value: Int, _ completion: (Int) -> Void) {
        completion(value)
    }

}
