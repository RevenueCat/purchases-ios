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
    private(set) var recordedHosts: [String?] = []
    private(set) var timeoutCallCount = 0
    private(set) var lastTimeoutHost: String?
    private(set) var lastTimeoutIsFallbackHostRequest: Bool?
    private(set) var lastTimeoutEndpointSupportsFallbackURLs: Bool?
    private(set) var lastTimeoutIsProxied: Bool?
    private(set) var lastTimeoutReTieredTimeoutsEnabled: Bool?

    init(defaultTimeout: TimeInterval) {
        self.defaultTimeout = defaultTimeout
        self.timeoutToReturn = defaultTimeout
    }

    var timeoutToReturn: TimeInterval

    func timeout(host: String?,
                 isFallbackHostRequest: Bool,
                 endpointSupportsFallbackURLs: Bool,
                 isProxied: Bool,
                 reTieredTimeoutsEnabled: Bool) -> TimeInterval {
        timeoutCallCount += 1
        lastTimeoutHost = host
        lastTimeoutIsFallbackHostRequest = isFallbackHostRequest
        lastTimeoutEndpointSupportsFallbackURLs = endpointSupportsFallbackURLs
        lastTimeoutIsProxied = isProxied
        lastTimeoutReTieredTimeoutsEnabled = reTieredTimeoutsEnabled
        return timeoutToReturn
    }

    func recordRequestResult(host: String?, _ result: HTTPRequestTimeoutManager.RequestResult) {
        recordedHosts.append(host)
        recordedResults.append(result)
    }

    func reset() {
        recordedResults.removeAll()
        recordedHosts.removeAll()
        timeoutCallCount = 0
        lastTimeoutHost = nil
        lastTimeoutIsFallbackHostRequest = nil
        lastTimeoutEndpointSupportsFallbackURLs = nil
        lastTimeoutIsProxied = nil
        lastTimeoutReTieredTimeoutsEnabled = nil
        timeoutToReturn = defaultTimeout
    }
}
