//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockDateProvider: DateProvider {
    var invokedNow = false
    var invokedNowCount = 0
    var stubbedNowResult: Date!

    init(stubbedNow: Date) {
        self.stubbedNowResult = stubbedNow
    }

    override func now() -> Date {
        invokedNow = true
        invokedNowCount += 1
        return stubbedNowResult
    }
}
