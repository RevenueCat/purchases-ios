//
//  HTTPRequestTimeoutManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 06/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

protocol HTTPRequestTimeoutManagerType {

    /// Determines the timeout to be used by the HTTP Request for the given path.
    ///
    /// - Parameters:
    ///   - path: The HTTP request path for which to determine the timeout
    ///   - isFallback: Whether this is a fallback request
    /// - Returns: The timeout interval in seconds
    func timeout(for path: HTTPRequestPath, isFallback: Bool) -> TimeInterval

    /// Updates the internal state in response to the result received from the backend.
    ///
    /// - Parameter result: The result of the HTTP request
    func recordRequestResult(_ result: HTTPRequestTimeoutManager.RequestResult)
}

class HTTPRequestTimeoutManager: HTTPRequestTimeoutManagerType {

    enum RequestResult {

        /// Request succeeded on the main backend
        case successOnMainBackend

        /// Request timed out on the main backend endpoint and supports fallback URLs
        case timeoutOnMainBackendForFallbackSupportedEndpoint

        /// Any other result (non-main backend, non-timeout errors, etc.)
        case other
    }

    enum Timeout: TimeInterval {

        /// The default timeout for backend requests that support a fallback
        case mainBackendRequestSupportingFallback = 5

        /// The reduced timeout for requests with fallback support after timeout
        case reduced = 2
    }

    // The amount of time after which the 'last timeout request received' state can be reset
    private static let timeoutResetInterval: TimeInterval = 600 // 10 minutes

    // The last time at which a timeout was received from the main backend
    private var lastTimeoutRequestTime: Date?

    // The default timeout to use
    private let defaultTimeout: TimeInterval

    private let dateProvider: DateProvider

    init(
        defaultTimeout: TimeInterval,
        dateProvider: DateProvider = .init()
    ) {
        self.defaultTimeout = defaultTimeout
        self.dateProvider = dateProvider
    }

    func timeout(for path: HTTPRequestPath, isFallback: Bool) -> TimeInterval {
        if shouldResetTimeout {
            resetLastTimeoutRequestTime()
        }

        let timeout: TimeInterval

        // A fallback request or a request that doesn't support a fallback
        if isFallback || !path.supportsFallbackURLs {
            timeout = self.defaultTimeout
        }
        // Main backend request that supports fallback when a timeout was previously received from the main backend
        else if lastTimeoutRequestTime != nil {
            timeout = Timeout.reduced.rawValue
        }
        // Main backend request that supports fallback, no timeout received recently
        else {
            timeout = Timeout.mainBackendRequestSupportingFallback.rawValue
        }

        return timeout
    }

    func recordRequestResult(_ result: RequestResult) {
        switch result {
        case .successOnMainBackend:
            resetLastTimeoutRequestTime()
        case .timeoutOnMainBackendForFallbackSupportedEndpoint:
            lastTimeoutRequestTime = dateProvider.now()
        case .other:
            break
        }
    }

    private func resetLastTimeoutRequestTime() {
        lastTimeoutRequestTime = nil
    }

    private var shouldResetTimeout: Bool {
        guard let lastTimeoutRequestTime else { return false }

        let timeElapsed = dateProvider.now().timeIntervalSince(lastTimeoutRequestTime)
        return timeElapsed >= Self.timeoutResetInterval
    }
}
