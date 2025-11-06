//
//  HTTPRequestTimeoutManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 06/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

class HTTPRequestTimeoutManager {

    enum RequestResult {

        /// Request succeeded on the main backend
        case successOnMainBackend

        /// Request timed out on the main backend and supports fallback URLs
        case timeoutOnMainBackendSupportingFallback

        /// Any other result (non-main backend, non-timeout errors, etc.)
        case other
    }

    enum Timeout: TimeInterval {

        /// The default timeout
        case `default` = 30

        /// The default timeout for backend requests that support a fallback
        case defaultForMainBackendRequestSupportingFallback = 5

        /// The reduced timeout for requests with fallback support after timeout
        case reduced = 2
    }

    // The amount of time after which the 'last timeout request received' state can be reset
    private static let timeoutResetInterval: TimeInterval = 10

    // The last time at which a timeout was received from the main backend
    private var lastTimeoutRequestTime: Date?

    private let dateProvider: DateProvider

    init(dateProvider: DateProvider) {
        self.dateProvider = dateProvider
    }

    /// Determines the timeout to be used by the HTTP Request for the given path.
    ///
    /// - Parameters:
    ///   - path: The HTTP request path for which to determine the timeout
    ///   - isFallback: Whether this is a fallback request
    /// - Returns: The timeout interval in seconds
    func timeout(for path: HTTPRequestPath, isFallback: Bool) -> TimeInterval {
        if shouldResetTimeout {
            resetlastTimeoutRequestTime()
        }

        let timeout: Timeout

        // A fallback request or a request that supports a fallback
        if isFallback || path.fallbackUrls.isEmpty {
            timeout = .default
        }
        // Main backend request when a timeout was previously received from the main backend
        else if lastTimeoutRequestTime != nil {
            timeout = .reduced
        }
        // Main backend request that supports fallback, no timeout received recently
        else {
            timeout = .defaultForMainBackendRequestSupportingFallback
        }

        return timeout.rawValue
    }

    /// Updates the internal state in response to the result received from the backend.
    ///
    /// - Parameter result: The result of the HTTP request
    func recordRequestResult(_ result: RequestResult) {
        switch result {
        case .successOnMainBackend:
            resetlastTimeoutRequestTime()
        case .timeoutOnMainBackendSupportingFallback:
            lastTimeoutRequestTime = dateProvider.now()
        case .other:
            break
        }
    }

    private func resetlastTimeoutRequestTime() {
        lastTimeoutRequestTime = nil
    }

    private var shouldResetTimeout: Bool {
        guard let lastTimeoutRequestTime else { return false }

        let timeElapsed = dateProvider.now().timeIntervalSince1970 - lastTimeoutRequestTime.timeIntervalSince1970
        return timeElapsed >= Self.timeoutResetInterval
    }
}
