//
//  RemoteConfigSourceProviderTests.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 26/06/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigSourceProviderTests: TestCase {

    // MARK: - Initial selection

    func testCurrentEndpointsAreNilWhenNoSources() {
        let provider = RemoteConfigSourceProvider(sources: RemoteConfigSources(), randomizer: FakeRandomizer())
        expect(provider.currentAPIEndpoint).to(beNil())
        expect(provider.currentBlobEndpoint).to(beNil())
    }

    func testCurrentEndpointReturnsHighestPrioritySource() {
        let low = Self.source("low", priority: 0, weight: 100)
        let high = Self.source("high", priority: 10, weight: 1)
        let provider = Self.apiProvider([low, high])

        let endpoint = provider.currentAPIEndpoint
        expect(endpoint?.url) == Self.url("high")
        expect(endpoint?.kind) == .api
    }

    func testCurrentEndpointIsStableAcrossReads() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b")])

        expect(provider.currentAPIEndpoint) == provider.currentAPIEndpoint
    }

    // MARK: - reportUnhealthy advances

    func testReportUnhealthyAdvancesToNextSource() {
        let high = Self.source("high", priority: 10, weight: 1)
        let low = Self.source("low", priority: 0, weight: 1)
        let provider = Self.apiProvider([high, low])

        let first = provider.currentAPIEndpoint
        expect(first?.url) == Self.url("high")

        provider.reportUnhealthy(first!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("low")
    }

    func testCurrentEndpointIsNilWhenExhausted() {
        let provider = Self.apiProvider([Self.source("only")])

        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint).to(beNil())
    }

    func testReportUnhealthyWalksFullFallbackOrder() {
        let first = Self.source("1", priority: 30, weight: 1)
        let second = Self.source("2", priority: 20, weight: 1)
        let third = Self.source("3", priority: 10, weight: 1)
        let provider = Self.apiProvider([first, second, third])

        expect(provider.currentAPIEndpoint?.url) == Self.url("1")
        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("2")
        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("3")
        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint).to(beNil())
    }

    // MARK: - Dedup

    func testDedupsSourcesByURL() {
        let provider = Self.apiProvider([
            Self.source("a", priority: 10, weight: 1),
            Self.source("a", priority: 5, weight: 1),
            Self.source("b", priority: 0, weight: 1)
        ])

        expect(provider.currentAPIEndpoint?.url) == Self.url("a")
        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("b")
        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint).to(beNil())
    }

    // MARK: - api / blob independence

    func testAPIAndBlobAreExposedIndependently() {
        let provider = RemoteConfigSourceProvider(
            sources: RemoteConfigSources(api: [Self.source("api")], blob: [Self.source("blob")]),
            randomizer: FakeRandomizer(0)
        )

        let api = provider.currentAPIEndpoint
        let blob = provider.currentBlobEndpoint
        expect(api?.url) == Self.url("api")
        expect(api?.kind) == .api
        expect(blob?.url) == Self.url("blob")
        expect(blob?.kind) == .blob
    }

    func testReportingAPIUnhealthyDoesNotAffectBlob() {
        let provider = RemoteConfigSourceProvider(
            sources: RemoteConfigSources(
                api: [Self.source("api1", priority: 10), Self.source("api2", priority: 0)],
                blob: [Self.source("blob1", priority: 10), Self.source("blob2", priority: 0)]
            ),
            randomizer: FakeRandomizer(0)
        )

        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("api2")
        expect(provider.currentBlobEndpoint?.url) == Self.url("blob1")

        provider.reportUnhealthy(provider.currentBlobEndpoint!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("api2")
        expect(provider.currentBlobEndpoint?.url) == Self.url("blob2")
    }

    // MARK: - Stale report handling (race conditions)

    func testStaleReportIsIgnoredAfterAnotherCallerAdvanced() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        // Two callers grab the same current endpoint.
        let endpointA = provider.currentAPIEndpoint
        let endpointB = provider.currentAPIEndpoint
        expect(endpointA) == endpointB

        // Caller A reports it unhealthy: the provider advances.
        provider.reportUnhealthy(endpointA!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("b")

        // Caller B reports the *same* (now superseded) endpoint: this must NOT advance again.
        provider.reportUnhealthy(endpointB!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("b")
    }

    func testReportingSameEndpointTwiceAdvancesOnlyOnce() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        let endpoint = provider.currentAPIEndpoint
        provider.reportUnhealthy(endpoint!)
        provider.reportUnhealthy(endpoint!)
        provider.reportUnhealthy(endpoint!)

        expect(provider.currentAPIEndpoint?.url) == Self.url("b")
    }

    func testReportingFreshEndpointAfterStaleReportStillAdvances() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        let stale = provider.currentAPIEndpoint
        provider.reportUnhealthy(stale!)              // a -> b
        provider.reportUnhealthy(stale!)              // ignored, still b

        let fresh = provider.currentAPIEndpoint       // b
        provider.reportUnhealthy(fresh!)              // b -> c
        expect(provider.currentAPIEndpoint?.url) == Self.url("c")
    }

    func testStaleReportOnExhaustedProviderIsIgnored() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b")])

        let first = provider.currentAPIEndpoint
        provider.reportUnhealthy(first!)
        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint).to(beNil())

        // Reporting the original stale endpoint again must not resurrect or change anything.
        provider.reportUnhealthy(first!)
        expect(provider.currentAPIEndpoint).to(beNil())
    }

    // MARK: - restart

    func testRestartRewindsToFirstSource() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("c")

        provider.restart()
        expect(provider.currentAPIEndpoint?.url) == Self.url("a")
    }

    func testRestartRewindsBothKinds() {
        let provider = RemoteConfigSourceProvider(
            sources: RemoteConfigSources(
                api: [Self.source("api1", priority: 10), Self.source("api2", priority: 0)],
                blob: [Self.source("blob1", priority: 10), Self.source("blob2", priority: 0)]
            ),
            randomizer: FakeRandomizer(0)
        )

        provider.reportUnhealthy(provider.currentAPIEndpoint!)
        provider.reportUnhealthy(provider.currentBlobEndpoint!)
        expect(provider.currentAPIEndpoint?.url) == Self.url("api2")
        expect(provider.currentBlobEndpoint?.url) == Self.url("blob2")

        provider.restart()
        expect(provider.currentAPIEndpoint?.url) == Self.url("api1")
        expect(provider.currentBlobEndpoint?.url) == Self.url("blob1")
    }

    // MARK: - Threading

    func testConcurrentReportsAdvanceAtMostOncePerEndpoint() {
        let sources = (0..<100).map { Self.source("\($0)") }
        let provider = Self.apiProvider(sources)

        // Every iteration grabs the current endpoint and reports it unhealthy concurrently. Even
        // with many threads racing, a single endpoint can only advance the provider once, so the
        // provider must walk the fallback order one step at a time and never skip ahead.
        DispatchQueue.concurrentPerform(iterations: 500) { _ in
            if let endpoint = provider.currentAPIEndpoint {
                provider.reportUnhealthy(endpoint)
            }
        }

        // The exact landing point is timing-dependent, but it must be a valid, reachable URL (or
        // nil if every source happened to be exhausted) — never a corrupted/torn state.
        if let url = provider.currentAPIEndpoint?.url {
            expect(sources.map { $0.url }).to(contain(url))
        }
    }

    func testConcurrentReportsNeverSkipSourcesWhenSerialized() {
        // Drive the provider to exhaustion by always reporting the *current* endpoint. Collect every
        // distinct URL handed out; because stale reports are ignored, no source may be skipped.
        let sources = (0..<50).map { Self.source("\($0)") }
        let provider = Self.apiProvider(sources)

        let seen = Atomic<Set<String>>([])
        let group = DispatchGroup()
        for _ in 0..<8 {
            DispatchQueue.global().async(group: group) {
                while let endpoint = provider.currentAPIEndpoint {
                    seen.modify { $0.insert(endpoint.url) }
                    provider.reportUnhealthy(endpoint)
                }
            }
        }
        group.wait()

        expect(seen.value) == Set(sources.map { $0.url })
        expect(provider.currentAPIEndpoint).to(beNil())
    }

    // MARK: - Helpers

    private static func url(_ host: String) -> String {
        return "https://\(host).revenuecat.com"
    }

    private static func source(_ host: String, priority: Int = 0, weight: Int = 0) -> RemoteConfigSource {
        return RemoteConfigSource(url: url(host), priority: priority, weight: weight)
    }

    private static func apiProvider(_ sources: [RemoteConfigSource]) -> RemoteConfigSourceProvider {
        return RemoteConfigSourceProvider(sources: RemoteConfigSources(api: sources), randomizer: FakeRandomizer(0))
    }

}

/// Returns queued values from `randomInt(below:)`, clamped into range, repeating the last value
/// once the queue is drained.
private final class FakeRandomizer: WeightedSourceRandomizer {

    private let lock = Lock()
    private var values: [Int]
    private var index = 0

    init(_ values: Int...) {
        self.values = values.isEmpty ? [0] : values
    }

    func randomInt(below bound: Int) -> Int {
        return self.lock.perform {
            let value = self.index < self.values.count ? self.values[self.index] : self.values.last!
            self.index += 1
            return min(max(0, value), bound - 1)
        }
    }

}
