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

class TimingUtilAsyncTests: TestCase {

    private var clock: TestClock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.clock = TestClock()
    }

    func testMeasureNonThrowingBlockReturnsValueAndDuration() async {
        let expectedResult = Int.random(in: 0..<1000)
        let sleepDuration: DispatchTimeInterval = .seconds(10)

        let (result, time) = await TimingUtil.measure(self.clock) { [clock = self.clock!] () -> Int in
            clock.advance(by: sleepDuration)
            await Self.asyncMethod()

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
        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .seconds(10)
        let sleepDuration = threshold + .seconds(-5)

        let result: Int = await TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                                                  message: "Too slow",
                                                                  clock: self.clock) { [clock = self.clock!] in
            clock.advance(by: sleepDuration)
            await Self.asyncMethod()

            return expectedResult
        }

        expect(result) == expectedResult
        expect(self.logger.messages).to(beEmpty())
    }

    func testMeasureAndLogWithResult() async {
        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .seconds(10)
        let sleepDuration = threshold + .seconds(10)

        let message = "Computation took too long"
        let level: LogLevel = .info

        let result: Int = await TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                                                  message: message,
                                                                  level: level,
                                                                  clock: self.clock) { [clock = self.clock!] in
            clock.advance(by: sleepDuration)
            await Self.asyncMethod()

            return expectedResult
        }

        expect(result) == expectedResult

        // Expected: 🍎⚠️ Computation took too long (0.02 seconds)
        self.logger.verifyMessageWasLogged(
            String(format: "%@ %@ (%.2f seconds)",
                   LogIntent.appleWarning.prefix,
                   message,
                   sleepDuration.seconds),
            level: level
        )
    }

    func testMeasureAndLogThrowsError() async {
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

        expect(self.logger.messages).to(beEmpty())
    }

    func testMeasureSyncAndLogDoesNotLogIfLowerThanThreshold() {
        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .seconds(10)
        let sleepDuration = threshold + .seconds(-5)

        let result: Int = TimingUtil.measureSyncAndLogIfTooSlow(threshold: threshold.seconds,
                                                                message: "Too slow",
                                                                clock: self.clock) { [clock = self.clock!] in
            clock.advance(by: sleepDuration)
            return expectedResult
        }

        expect(result) == expectedResult
        expect(self.logger.messages).to(beEmpty())
    }

    func testMeasureSyncAndLogThrowsError() {
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

        expect(self.logger.messages).to(beEmpty())
    }

    func testMeasureSyncAndLogWithResult() {
        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .seconds(10)
        let sleepDuration = threshold + .seconds(10)

        let message = "Computation took too long"
        let level: LogLevel = .info

        let result: Int = TimingUtil.measureSyncAndLogIfTooSlow(
            threshold: threshold.seconds,
            message: message,
            level: level,
            clock: self.clock
        ) { [clock = self.clock!] in
            clock.advance(by: sleepDuration)

            return expectedResult
        }

        expect(result) == expectedResult

        // Expected: 🍎⚠️ Computation took too long (0.02 seconds)
        self.logger.verifyMessageWasLogged(
            String(format: "%@ %@ (%.2f seconds)",
                   LogIntent.appleWarning.prefix,
                   message,
                   sleepDuration.seconds),
            level: level
        )
    }

    private static func asyncMethod() async {}

}

class TimingUtilCompletionBlockTests: TestCase {

    private var clock: TestClock!

    override func setUp() {
        super.setUp()

        self.clock = TestClock()
    }

    func testMeasureWithCompletionBlock() {
        let expectedResult: Int = .random(in: 0..<1000)
        let sleepDuration: DispatchTimeInterval = .seconds(10)

        var result: Int?
        var duration: TimingUtil.Duration?

        TimingUtil.measure(self.clock) { [clock = self.clock!] completion in
            clock.advance(by: sleepDuration)
            Self.asynchronousWork(expectedResult, completion)
        } result: { (value: Int, time: TimingUtil.Duration) in
            result = value
            duration = time
        }

        expect(result).toEventuallyNot(beNil())
        expect(result) == expectedResult
        expect(duration) > 0
        expect(duration).to(beCloseTo(sleepDuration.seconds, within: 0.01))
    }

    func testMeasureAndLogDoesNotLogIfLowerThanThreshold() {
        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .seconds(10)
        let sleepDuration = threshold + .seconds(-5)

        var result: Int?

        TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                          message: "Too slow",
                                          clock: self.clock) { [clock = self.clock!] completion in
            clock.advance(by: sleepDuration)
            Self.asynchronousWork(expectedResult, completion)
        } result: { value in
            result = value
        }

        expect(result).toEventuallyNot(beNil())
        expect(result) == expectedResult
        expect(self.logger.messages).to(beEmpty())
    }

    func testMeasureAndLogWithResult() {
        let expectedResult = Int.random(in: 0..<1000)
        let threshold: DispatchTimeInterval = .seconds(10)
        let sleepDuration = threshold + .seconds(10)

        let message = "Computation took too long"
        let level: LogLevel = .info

        var result: Int?

        TimingUtil.measureAndLogIfTooSlow(threshold: threshold.seconds,
                                          message: message,
                                          level: level,
                                          clock: self.clock) { [clock = self.clock!] completion in
            clock.advance(by: sleepDuration)
            Self.asynchronousWork(expectedResult, completion)
        } result: { value in
            result = value
        }

        expect(result).toEventuallyNot(beNil())
        expect(result) == expectedResult

        self.logger.verifyMessageWasLogged(
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
