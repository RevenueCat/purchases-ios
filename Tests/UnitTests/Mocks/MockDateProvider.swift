//
// Created by RevenueCat on 2/27/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockDateProvider: DateProvider {

    private let dates: [Date]
    // `now()` can be called concurrently (e.g. parallel `post(receipt:)` calls), so the
    // index must be mutated atomically to avoid a data race that drops increments.
    private let currentIndex: Atomic<Int> = .init(0)

    var invokedNowCount: Int {
        return self.currentIndex.value
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
        self.dates = [stubbedNow]
    }

    override func now() -> Date {
        return self.currentIndex.modify { index in
            let date = self.dates[min(index, self.dates.count - 1)]
            index += 1
            return date
        }
    }
}

extension MockDateProvider: @unchecked Sendable {}

class MockCurrentDateProvider: DateProvider, @unchecked Sendable {
    private var date = Date(timeIntervalSince1970: 0)

    func advance(by timeInterval: TimeInterval) {
        date = date.advanced(by: timeInterval)
    }

    override func now() -> Date {
        date
    }
}
