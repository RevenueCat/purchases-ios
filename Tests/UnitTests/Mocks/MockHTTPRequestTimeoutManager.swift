//
//  MockHTTPRequestTimeoutManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 07/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockHTTPRequestTimeoutManager: HTTPRequestTimeoutManagerType {

    private let defaultTimeout: TimeInterval
    private(set) var recordedResults: [HTTPRequestTimeoutManager.RequestResult] = []
    private(set) var timeoutCallCount = 0
    private(set) var lastTimeoutIsFallback: Bool?
    private(set) var lastTimeoutFallbackAvailable: Bool?

    init(defaultTimeout: TimeInterval) {
        self.defaultTimeout = defaultTimeout
        self.timeoutToReturn = defaultTimeout
    }

    var timeoutToReturn: TimeInterval

    func timeout(isFallback: Bool, fallbackAvailable: Bool) -> TimeInterval {
        timeoutCallCount += 1
        lastTimeoutIsFallback = isFallback
        lastTimeoutFallbackAvailable = fallbackAvailable
        return timeoutToReturn
    }

    func recordRequestResult(_ result: HTTPRequestTimeoutManager.RequestResult) {
        recordedResults.append(result)
    }

    func reset() {
        recordedResults.removeAll()
        timeoutCallCount = 0
        lastTimeoutIsFallback = nil
        lastTimeoutFallbackAvailable = nil
        timeoutToReturn = defaultTimeout
    }
}
