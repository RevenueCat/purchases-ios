//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockDateProvider: DateProvider {

    private var dates: [Date]
    private var currentIndex = 0

    var invokedNowCount: Int {
        return currentIndex
    }
    var invokedNow: Bool {
        return invokedNowCount > 0
    }

    init(stubbedNow: Date, subsequentNows: Date...) {
        self.dates = [stubbedNow] + subsequentNows
    }

    init(stubbedNow: Date, subsequentNows: [Date]) {
        self.dates = [stubbedNow] + subsequentNows
    }

    init(stubbedNow: Date) {
        self.stubbedNowResult = stubbedNow
    }

    override func now() -> Date {
        defer { currentIndex += 1 }
        return dates[min(currentIndex, dates.count - 1)]
    }
}
