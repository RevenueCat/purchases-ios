//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Nimble
@_spi(Internal) @testable import RevenueCat

class TestLogHandlerLifecycleTests: TestCase {

    func testRetainedStoppedLoggerDoesNotReceiveSubsequentTestMessages() {
        let previousLogger = TestLogHandler(testIdentifier: "previous test")
        Logger.error("before observation stops")
        let previousMessages = previousLogger.messages.map(\.message)
        expect(previousMessages).to(haveCount(1))

        previousLogger.stopObserving()
        previousLogger.stopObserving()

        let currentLogger = TestLogHandler(testIdentifier: "current test")
        defer { currentLogger.stopObserving() }
        Logger.error("after observation stops")

        expect(previousLogger.messages.map(\.message)) == previousMessages
        expect(currentLogger.messages).to(haveCount(1))
        expect(currentLogger.messages.last?.message).to(contain("after observation stops"))
    }

}
