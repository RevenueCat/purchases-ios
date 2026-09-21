//
//  APISourceFailover.swift
//  RevenueCat
//
//  Created by Toni Rico on 27/07/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol APISourceFailoverType: AnyObject, Sendable {

    /// The source a request to `path` should target, or `nil` to keep using the path's default host.
    func currentSource(for path: HTTPRequestPath, isFallbackAttempt: Bool) -> APISourceFailover.ResolvedSource?

    /// Decides what to do after a request to `source` failed in a way that may indicate a source
    /// outage, health-checking the source to tell an outage apart from anything else.
    func onRequestFailure(_ source: APISourceFailover.ResolvedSource,
                          completion: @escaping @Sendable (APISourceFailover.FailureDecision) -> Void)

}

/// Decides which API source a request should target and whether a failed request should fail over to
/// the next source. Only failures that point at the host (connection-level failures and 5xx
/// responses, never device-connectivity errors or 4xx — the caller gates on
/// `NetworkError.isAllowedToRetryWithFallbackHost`) can trigger a failover, and only after a health
/// check against the current source fails: a 2xx health response means the source is healthy (the
/// request failure was something else, e.g. endpoint-specific), so the original error surfaces
/// without switching hosts. A source whose health check returns non-2xx or cannot complete is
/// reported unhealthy and the next one takes over.
final class APISourceFailover: APISourceFailoverType {

    /// A source handle plus its parsed base URL; only parseable sources are ever handed out.
    struct ResolvedSource {

        let handle: RemoteConfigSourceHandle
        let url: URL

    }

    enum FailureDecision {

        /// The current source failed its health check; retry the request on the associated source.
        case retryNextSource(ResolvedSource)

        /// The current source is healthy, so failing over is pointless: surface the original error.
        case sourceHealthy

        /// Every source has been reported unhealthy; surface the original error.
        case sourcesExhausted

    }

    private let usesRemoteConfigAPISources: Bool
    private let sourceProvider: RemoteConfigSourceProviderType
    private let healthChecker: SourceHealthCheckerType

    /// - Parameter usesRemoteConfigAPISources: the `usesRemoteConfigAPISources` dangerous setting.
    /// Taken as a plain value because the whole settings chain is immutable per SDK instance.
    init(usesRemoteConfigAPISources: Bool,
         sourceProvider: RemoteConfigSourceProviderType,
         healthChecker: SourceHealthCheckerType) {
        self.usesRemoteConfigAPISources = usesRemoteConfigAPISources
        self.sourceProvider = sourceProvider
        self.healthChecker = healthChecker
    }

    /// The source a request to `path` should target, or `nil` to keep using the path's default host.
    ///
    /// API sources apply only when: the `usesRemoteConfigAPISources` dangerous setting is enabled, no
    /// proxy is configured (a proxy pins every request to itself), this is not an endpoint
    /// fallback-host attempt, the path opts in via `usesAPISources`, and `SystemInfo.apiBaseURL`
    /// still holds its default (an override pins the host, e.g. in tests).
    func currentSource(for path: HTTPRequestPath, isFallbackAttempt: Bool) -> ResolvedSource? {
        guard self.usesRemoteConfigAPISources,
              SystemInfo.proxyURL == nil,
              !isFallbackAttempt,
              path.usesAPISources,
              SystemInfo.apiBaseURL == SystemInfo.defaultApiBaseURL else {
            return nil
        }
        return self.currentResolvedSource()
    }

    func onRequestFailure(_ source: ResolvedSource,
                          completion: @escaping @Sendable (FailureDecision) -> Void) {
        self.healthChecker.checkHealth(ofSourceBaseURL: source.url) { isHealthy in
            if isHealthy {
                Logger.debug(Strings.network.api_source_healthy_despite_failure(host: source.handle.url))
                completion(.sourceHealthy)
                return
            }
            self.sourceProvider.reportUnhealthy(source.handle)
            completion(self.currentResolvedSource().map(FailureDecision.retryNextSource) ?? .sourcesExhausted)
        }
    }

    /// The provider's current source with its URL parsed. Sources with malformed URLs are reported
    /// unhealthy and skipped, so they participate in failover instead of silently pinning requests to
    /// the default host. The walk ends when the provider runs out of sources.
    private func currentResolvedSource() -> ResolvedSource? {
        while let handle = self.sourceProvider.currentAPISource() {
            if let url = Self.parseAbsoluteURL(handle.url) {
                return ResolvedSource(handle: handle, url: url)
            }
            Logger.warn(Strings.network.skipping_malformed_api_source_url(url: handle.url))
            self.sourceProvider.reportUnhealthy(handle)
        }
        return nil
    }

    /// Parses `string` as an absolute base URL. `URL(string:)` alone is too lenient (on modern
    /// Foundation almost any string parses, e.g. scheme-less hosts or relative paths), so a scheme
    /// and a host are additionally required — anything less would build requests that can only fail.
    private static func parseAbsoluteURL(_ string: String) -> URL? {
        guard let url = URL(string: string),
              url.scheme != nil,
              url.host != nil else {
            return nil
        }
        return url
    }

}

// @unchecked because the compiler can't verify it: all dependencies are themselves thread-safe and
// this class holds no mutable state.
extension APISourceFailover: @unchecked Sendable {}
