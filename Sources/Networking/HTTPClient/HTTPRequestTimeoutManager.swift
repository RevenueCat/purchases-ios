//
//  HTTPRequestTimeoutManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 06/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

protocol HTTPRequestTimeoutManagerType {

    /// Determines the timeout to be used by an HTTP request attempt.
    ///
    /// - Parameters:
    ///   - host: The resolved host string of the attempt, used to look up the per-host fail-fast memory.
    ///   - isFallbackHostRequest: Whether this attempt targets a fallback host.
    ///   - endpointSupportsFallbackURLs: Whether the endpoint has fallback-URL support.
    ///   - isProxied: Whether a proxy URL is set.
    /// - Returns: The timeout interval in seconds.
    func timeout(host: String?,
                 isFallbackHostRequest: Bool,
                 endpointSupportsFallbackURLs: Bool,
                 isProxied: Bool) -> TimeInterval

    /// Updates the internal state in response to the result of an HTTP request attempt.
    ///
    /// - Parameters:
    ///   - host: The resolved host string of the attempt.
    ///   - result: The result of the HTTP request.
    func recordRequestResult(host: String?, _ result: HTTPRequestTimeoutManager.RequestResult)
}

class HTTPRequestTimeoutManager: HTTPRequestTimeoutManagerType {

    enum RequestResult {

        /// Request succeeded on the main source.
        case successOnMainBackend

        /// Request timed out on the main source.
        case mainSourceTimedOut

        /// Any other result (fallback-host request, non-timeout errors, etc.)
        case other
    }

    /// Timeout tiers, in seconds.
    enum Timeout {

        /// Main-source request to an endpoint with no fallback-URL support.
        static let mainSourceNoFallback: TimeInterval = 15

        /// Main-source request to an endpoint with no fallback-URL support, when the source recently timed out.
        static let mainSourceNoFallbackReduced: TimeInterval = 5

        /// Main-source request to an endpoint with fallback-URL support.
        static let mainSourceSupportingFallback: TimeInterval = 5

        /// Main-source request to an endpoint with fallback-URL support, when the source recently timed out.
        static let mainSourceSupportingFallbackReduced: TimeInterval = 2

        /// Fallback-host and proxied requests (flat, never reduced).
        static let flat: TimeInterval = 30
    }

    // The amount of time after which a per-host timeout entry expires.
    private static let timeoutResetInterval: TimeInterval = 600 // 10 minutes

    // The last time a timeout was recorded, keyed by resolved host string. Guarded by `lock`.
    private var lastTimeoutByHost: [String: Date] = [:]

    // When the developer sets a custom `networkTimeout`, it replaces the built-in base/flat tiers.
    private let networkTimeout: NetworkTimeout

    private let dateProvider: DateProvider
    private let lock = Lock()

    init(
        networkTimeout: NetworkTimeout = .default,
        dateProvider: DateProvider = .init()
    ) {
        self.networkTimeout = networkTimeout
        self.dateProvider = dateProvider
    }

    func timeout(host: String?,
                 isFallbackHostRequest: Bool,
                 endpointSupportsFallbackURLs: Bool,
                 isProxied: Bool) -> TimeInterval {
        // Fallback-host and proxied requests use a flat timeout and never consult the per-host memory.
        guard !isFallbackHostRequest, !isProxied else {
            return self.baseTimeout(default: Timeout.flat)
        }

        let sourceRecentlyTimedOut = host.map { self.hasRecentTimeout(forHost: $0) } ?? false

        // Base tiers honor a custom `networkTimeout`; the reduced fail-fast tiers stay fixed.
        switch (endpointSupportsFallbackURLs, sourceRecentlyTimedOut) {
        case (true, false): return self.baseTimeout(default: Timeout.mainSourceSupportingFallback)
        case (true, true): return Timeout.mainSourceSupportingFallbackReduced
        case (false, false): return self.baseTimeout(default: Timeout.mainSourceNoFallback)
        case (false, true): return Timeout.mainSourceNoFallbackReduced
        }
    }

    /// The base/flat timeout to use: the developer's custom value when set, otherwise the built-in tier.
    private func baseTimeout(default defaultValue: TimeInterval) -> TimeInterval {
        switch self.networkTimeout {
        case .default: return defaultValue
        case let .custom(value): return value
        }
    }

    func recordRequestResult(host: String?, _ result: RequestResult) {
        guard let host else { return }

        switch result {
        case .successOnMainBackend:
            self.lock.perform { _ = self.lastTimeoutByHost.removeValue(forKey: host) }
        case .mainSourceTimedOut:
            self.lock.perform { self.lastTimeoutByHost[host] = self.dateProvider.now() }
        case .other:
            break
        }
    }

    /// Whether `host` has a non-expired timeout entry. Prunes the entry if it has expired.
    private func hasRecentTimeout(forHost host: String) -> Bool {
        return self.lock.perform {
            guard let lastTimeout = self.lastTimeoutByHost[host] else { return false }

            if self.dateProvider.now().timeIntervalSince(lastTimeout) >= Self.timeoutResetInterval {
                self.lastTimeoutByHost.removeValue(forKey: host)
                return false
            }

            return true
        }
    }
}
