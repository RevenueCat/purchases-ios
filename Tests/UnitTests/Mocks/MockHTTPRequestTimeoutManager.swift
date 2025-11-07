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

    private(set) var recordedResults: [HTTPRequestTimeoutManager.RequestResult] = []
    private(set) var timeoutCallCount = 0
    private(set) var lastTimeoutPath: HTTPRequestPath?
    private(set) var lastTimeoutIsFallback: Bool?

    var timeoutToReturn: TimeInterval = HTTPRequestTimeoutManager.Timeout.default.rawValue

    func timeout(for path: HTTPRequestPath, isFallback: Bool) -> TimeInterval {
        timeoutCallCount += 1
        lastTimeoutPath = path
        lastTimeoutIsFallback = isFallback
        return timeoutToReturn
    }

    func recordRequestResult(_ result: HTTPRequestTimeoutManager.RequestResult) {
        recordedResults.append(result)
    }

    func reset() {
        recordedResults.removeAll()
        timeoutCallCount = 0
        lastTimeoutPath = nil
        lastTimeoutIsFallback = nil
        timeoutToReturn = HTTPRequestTimeoutManager.Timeout.default.rawValue
    }
}
