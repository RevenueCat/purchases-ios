//
//  SourceHealthChecker.swift
//  RevenueCat
//
//  Created by Toni Rico on 27/07/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol SourceHealthCheckerType: AnyObject, Sendable {

    /// Probes `<sourceBaseURL>/v1/health/connectivity`. Only a 2xx response is healthy; any other
    /// response or a connection failure is not. `completion` may be invoked synchronously (on a
    /// cache hit) or on a background queue.
    func checkHealth(ofSourceBaseURL url: URL, completion: @escaping @Sendable (Bool) -> Void)

}

/// Checks whether a source is healthy by hitting its `/v1/health/connectivity` endpoint: only a 2xx
/// response counts as healthy; any other response or a connection failure does not. Checks are
/// on-demand only (callers probe after a request to the source has already failed, never proactively).
///
/// Thread-safe: concurrent checks for the same source share a single request (joiners are completed
/// with the owner's result), and results are cached briefly so a burst of failing requests fires
/// one probe.
final class SourceHealthChecker: SourceHealthCheckerType {

    private static let healthPath = "v1/health/connectivity"
    private static let resultValidity: TimeInterval = 10
    private static let requestTimeout: TimeInterval = 5

    private struct CachedResult {
        let timestamp: Date
        let isHealthy: Bool
    }

    private struct State {
        /// A non-nil entry means a probe for that URL is in flight; joiners append their completions.
        var pendingCompletions: [URL: [@Sendable (Bool) -> Void]] = [:]
        var cachedResults: [URL: CachedResult] = [:]
    }

    private let state: Atomic<State> = .init(.init())
    private let session: URLSession
    private let dateProvider: DateProvider

    init(dateProvider: DateProvider = DateProvider()) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = Self.requestTimeout
        configuration.timeoutIntervalForResource = Self.requestTimeout
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
        self.dateProvider = dateProvider
    }

    func checkHealth(ofSourceBaseURL url: URL, completion: @escaping @Sendable (Bool) -> Void) {
        let healthURL = Self.healthURL(forSourceBaseURL: url)

        enum Action {
            case complete(isHealthy: Bool)
            case joined
            case probe
        }

        let action: Action = self.state.modify { state in
            if let cached = state.cachedResults[healthURL],
               self.dateProvider.now().timeIntervalSince(cached.timestamp) < Self.resultValidity {
                return .complete(isHealthy: cached.isHealthy)
            }
            if state.pendingCompletions[healthURL] != nil {
                state.pendingCompletions[healthURL]?.append(completion)
                return .joined
            }
            state.pendingCompletions[healthURL] = [completion]
            return .probe
        }

        switch action {
        case let .complete(isHealthy):
            completion(isHealthy)
        case .joined:
            break
        case .probe:
            self.performProbe(healthURL: healthURL)
        }
    }

    private func performProbe(healthURL: URL) {
        let task = self.session.dataTask(with: healthURL) { _, response, error in
            let isHealthy: Bool
            if let error = error {
                Logger.verbose(Strings.network.api_source_health_check_failed_to_connect(url: healthURL,
                                                                                         error: error))
                isHealthy = false
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                isHealthy = (200..<300).contains(statusCode)
                Logger.verbose(Strings.network.api_source_health_check_completed(url: healthURL,
                                                                                 statusCode: statusCode,
                                                                                 isHealthy: isHealthy))
            }

            let completions: [@Sendable (Bool) -> Void] = self.state.modify { state in
                state.cachedResults[healthURL] = CachedResult(timestamp: self.dateProvider.now(),
                                                              isHealthy: isHealthy)
                return state.pendingCompletions.removeValue(forKey: healthURL) ?? []
            }
            completions.forEach { $0(isHealthy) }
        }
        task.resume()
    }

    /// `https://host/` and `https://host` both map to `https://host/v1/health/connectivity`.
    private static func healthURL(forSourceBaseURL url: URL) -> URL {
        return url.appendingPathComponent(Self.healthPath)
    }

}

// @unchecked because the compiler can't verify the hand-rolled synchronization:
// all mutable state is guarded by `Atomic`.
extension SourceHealthChecker: @unchecked Sendable {}
