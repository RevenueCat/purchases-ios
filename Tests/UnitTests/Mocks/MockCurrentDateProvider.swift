//
//  MockCurrentDateProvider.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 06/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockCurrentDateProvider: DateProvider, @unchecked Sendable {
    private var date = Date(timeIntervalSince1970: 0)

    func advance(by timeInterval: TimeInterval) {
        date = date.advanced(by: timeInterval)
    }

    override func now() -> Date {
        date
    }
}
