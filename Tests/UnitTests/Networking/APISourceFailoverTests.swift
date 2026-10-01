//
//  APISourceFailoverTests.swift
//  RevenueCat
//
//  Created by Toni Rico on 27/07/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class APISourceFailoverTests: TestCase {

    private static let eligiblePath: HTTPRequestPath = HTTPRequest.Path.getCustomerInfo(appUserID: "test-user-id")

    // MARK: - currentSource eligibility

    func testCurrentSourceResolvesTheProvidersCurrentSourceWhenEligible() {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])
        let source = Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: false)

        expect(source?.url) == URL(string: "https://a.revenuecat.com/")
        expect(source?.handle.url) == "https://a.revenuecat.com/"
    }

    func testCurrentSourceIsNilWhenTheDangerousSettingIsDisabled() {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])
        let failover = Self.failover(provider, usesRemoteConfigAPISources: false)

        expect(failover.currentSource(for: Self.eligiblePath, isFallbackAttempt: false)).to(beNil())
    }

    func testCurrentSourceIsNilForEndpointFallbackAttempts() {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])

        expect(Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: true))
            .to(beNil())
    }

    func testCurrentSourceIsNilForPathsThatDoNotUseAPISources() {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])
        let path: HTTPRequestPath = HTTPRequest.DiagnosticsPath.postDiagnostics

        expect(Self.failover(provider).currentSource(for: path, isFallbackAttempt: false)).to(beNil())
    }

    func testCurrentSourceIsNilWhenProxyURLIsSet() throws {
        SystemInfo.proxyURL = try XCTUnwrap(URL(string: "https://proxy.rc-test.com"))
        defer { SystemInfo.proxyURL = nil }

        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])

        expect(Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
            .to(beNil())
    }

    func testCurrentSourceIsNilWhenTheAPIBaseURLIsOverridden() throws {
        SystemInfo.apiBaseURL = try XCTUnwrap(URL(string: "https://pinned-api.rc-test.com"))
        defer { SystemInfo.apiBaseURL = SystemInfo.defaultApiBaseURL }

        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])

        expect(Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
            .to(beNil())
    }

    func testCurrentSourceIsNilWhenTheProviderIsExhausted() {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])
        provider.reportUnhealthy(provider.currentAPISource()!)

        expect(Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
            .to(beNil())
    }

    func testCurrentSourceSkipsAndReportsSourcesWithMalformedURLs() {
        let provider = RecordingSourceProvider(urls: ["not a url", "https://b.revenuecat.com/"])
        let source = Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: false)

        expect(source?.url) == URL(string: "https://b.revenuecat.com/")
        expect(provider.unhealthyReports.value) == ["not a url"]
    }

    func testCurrentSourceSkipsAndReportsSourcesWithSchemelessURLs() {
        // `URL(string:)` parses these fine as relative URLs, so they need explicit rejection:
        // a request built against a base without a scheme and host can only fail.
        let provider = RecordingSourceProvider(urls: ["a.revenuecat.com/", "https://b.revenuecat.com/"])
        let source = Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: false)

        expect(source?.url) == URL(string: "https://b.revenuecat.com/")
        expect(provider.unhealthyReports.value) == ["a.revenuecat.com/"]
    }

    func testCurrentSourceIsNilWhenEverySourceURLIsMalformed() {
        let provider = RecordingSourceProvider(urls: ["not a url", "a.revenuecat.com/"])

        expect(Self.failover(provider).currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
            .to(beNil())
        expect(provider.unhealthyReports.value) == ["not a url", "a.revenuecat.com/"]
    }

    // MARK: - onRequestFailure

    func testOnRequestFailureDoesNotFailOverWhenTheSourcesHealthCheckPasses() throws {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/", "https://b.revenuecat.com/"])
        let healthChecker = MockSourceHealthChecker()
        healthChecker.stubbedIsHealthy.value = true
        let failover = Self.failover(provider, healthChecker: healthChecker)

        let source = try XCTUnwrap(failover.currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
        let decision = self.decision(of: failover, for: source)

        guard case .sourceHealthy = decision else {
            fail("Expected sourceHealthy, got \(String(describing: decision))")
            return
        }
        expect(provider.unhealthyReports.value).to(beEmpty())
    }

    func testOnRequestFailureFailsOverWhenTheHealthCheckFails() throws {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/", "https://b.revenuecat.com/"])
        let healthChecker = MockSourceHealthChecker()
        healthChecker.stubbedIsHealthy.value = false
        let failover = Self.failover(provider, healthChecker: healthChecker)

        let source = try XCTUnwrap(failover.currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
        let decision = self.decision(of: failover, for: source)

        guard case let .retryNextSource(next) = decision else {
            fail("Expected retryNextSource, got \(String(describing: decision))")
            return
        }
        expect(next.url) == URL(string: "https://b.revenuecat.com/")
        expect(provider.unhealthyReports.value) == ["https://a.revenuecat.com/"]
    }

    func testOnRequestFailureReportsExhaustionOnceTheLastSourceFailsItsHealthCheck() throws {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/"])
        let healthChecker = MockSourceHealthChecker()
        healthChecker.stubbedIsHealthy.value = false
        let failover = Self.failover(provider, healthChecker: healthChecker)

        let source = try XCTUnwrap(failover.currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
        let decision = self.decision(of: failover, for: source)

        guard case .sourcesExhausted = decision else {
            fail("Expected sourcesExhausted, got \(String(describing: decision))")
            return
        }
        expect(provider.unhealthyReports.value) == ["https://a.revenuecat.com/"]
    }

    func testOnRequestFailureHealthChecksTheFailedSource() throws {
        let provider = RecordingSourceProvider(urls: ["https://a.revenuecat.com/", "https://b.revenuecat.com/"])
        let healthChecker = MockSourceHealthChecker()
        let failover = Self.failover(provider, healthChecker: healthChecker)

        let source = try XCTUnwrap(failover.currentSource(for: Self.eligiblePath, isFallbackAttempt: false))
        _ = self.decision(of: failover, for: source)

        expect(healthChecker.checkedSourceURLs.value) == [URL(string: "https://a.revenuecat.com/")]
    }

    // MARK: - Helpers

    private static func failover(
        _ provider: RemoteConfigSourceProviderType,
        usesRemoteConfigAPISources: Bool = true,
        healthChecker: SourceHealthCheckerType = MockSourceHealthChecker()
    ) -> APISourceFailover {
        return APISourceFailover(
            usesRemoteConfigAPISources: usesRemoteConfigAPISources,
            sourceProvider: provider,
            healthChecker: healthChecker
        )
    }

    /// The mock health checker completes synchronously, so the decision is available on return.
    private func decision(
        of failover: APISourceFailover,
        for source: APISourceFailover.ResolvedSource
    ) -> APISourceFailover.FailureDecision? {
        let decision: Atomic<APISourceFailover.FailureDecision?> = .init(nil)
        failover.onRequestFailure(source) { decision.value = $0 }
        return decision.value
    }

}

/// A real `RemoteConfigSourceProvider` over the given API source urls (in priority order), wrapped to
/// record every `reportUnhealthy` call. `RemoteConfigSourceHandle` can only be created by the real
/// provider, so tests drive it instead of faking handles.
private final class RecordingSourceProvider: RemoteConfigSourceProviderType {

    let unhealthyReports: Atomic<[String]> = .init([])

    private let wrapped: RemoteConfigSourceProvider

    init(urls: [String]) {
        self.wrapped = RemoteConfigSourceProvider(topicStore: APISourceTopicStore(urls: urls))
    }

    func getCurrent(for purpose: RemoteConfigSourceHandle.Purpose) -> RemoteConfigSourceHandle? {
        return self.wrapped.getCurrent(for: purpose)
    }

    func reportUnhealthy(_ handle: RemoteConfigSourceHandle) {
        self.unhealthyReports.modify { $0.append(handle.url) }
        self.wrapped.reportUnhealthy(handle)
    }

    func restart(for purpose: RemoteConfigSourceHandle.Purpose) {
        self.wrapped.restart(for: purpose)
    }

    @discardableResult
    func restartIfExhausted(for purpose: RemoteConfigSourceHandle.Purpose) -> Bool {
        return self.wrapped.restartIfExhausted(for: purpose)
    }

}

/// A minimal `sources` topic store exposing the given API sources in order (priority = index), matching
/// the backend topic shape.
private final class APISourceTopicStore: RemoteConfigTopicStoreType {

    private let urls: [String]

    init(urls: [String]) {
        self.urls = urls
    }

    func topic(_ topic: RemoteConfigTopic) -> RemoteConfiguration.ConfigTopic? {
        guard topic == .sources else { return nil }
        return ["api": RemoteConfiguration.ConfigItem(content: [
            "sources": .array(self.urls.enumerated().map { index, url in
                .object([
                    "url": .string(url),
                    "priority": .int(index),
                    "weight": .int(1)
                ])
            })
        ])]
    }

}
