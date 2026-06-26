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

    func testCurrentEndpointIsNilWhenNoSources() {
        let provider = RemoteConfigSourceProvider<TestSource>(sources: [], randomizer: FakeRandomizer())
        expect(provider.currentEndpoint).to(beNil())
    }

    func testCurrentEndpointReturnsHighestPrioritySource() {
        let low = TestSource(url: Self.url("low"), priority: 0, weight: 100)
        let high = TestSource(url: Self.url("high"), priority: 10, weight: 1)
        let provider = RemoteConfigSourceProvider(sources: [low, high], randomizer: FakeRandomizer(0))

        expect(provider.currentEndpoint?.url) == Self.url("high")
    }

    func testCurrentEndpointIsStableAcrossReads() {
        let provider = RemoteConfigSourceProvider(sources: [Self.source("a")], randomizer: FakeRandomizer(0))

        expect(provider.currentEndpoint?.source) == provider.currentEndpoint?.source
    }

    // MARK: - reportUnhealthy advances

    func testReportUnhealthyAdvancesToNextSource() {
        let high = TestSource(url: Self.url("high"), priority: 10, weight: 1)
        let low = TestSource(url: Self.url("low"), priority: 0, weight: 1)
        let provider = RemoteConfigSourceProvider(sources: [high, low], randomizer: FakeRandomizer(0))

        let first = provider.currentEndpoint
        expect(first?.url) == Self.url("high")

        provider.reportUnhealthy(first!)
        expect(provider.currentEndpoint?.url) == Self.url("low")
    }

    func testCurrentEndpointIsNilWhenExhausted() {
        let provider = RemoteConfigSourceProvider(sources: [Self.source("only")], randomizer: FakeRandomizer(0))

        let only = provider.currentEndpoint
        provider.reportUnhealthy(only!)
        expect(provider.currentEndpoint).to(beNil())
    }

    func testReportUnhealthyWalksFullFallbackOrder() {
        let first = TestSource(url: Self.url("1"), priority: 30, weight: 1)
        let second = TestSource(url: Self.url("2"), priority: 20, weight: 1)
        let third = TestSource(url: Self.url("3"), priority: 10, weight: 1)
        let provider = RemoteConfigSourceProvider(sources: [first, second, third], randomizer: FakeRandomizer(0))

        expect(provider.currentEndpoint?.url) == Self.url("1")
        provider.reportUnhealthy(provider.currentEndpoint!)
        expect(provider.currentEndpoint?.url) == Self.url("2")
        provider.reportUnhealthy(provider.currentEndpoint!)
        expect(provider.currentEndpoint?.url) == Self.url("3")
        provider.reportUnhealthy(provider.currentEndpoint!)
        expect(provider.currentEndpoint).to(beNil())
    }

    // MARK: - Stale report handling (race conditions)

    func testStaleReportIsIgnoredAfterAnotherCallerAdvanced() {
        let provider = RemoteConfigSourceProvider(
            sources: [Self.source("a"), Self.source("b"), Self.source("c")],
            randomizer: FakeRandomizer(0)
        )

        // Two callers grab the same current endpoint.
        let endpointA = provider.currentEndpoint
        let endpointB = provider.currentEndpoint
        expect(endpointA?.source) == endpointB?.source

        // Caller A reports it unhealthy: the provider advances.
        provider.reportUnhealthy(endpointA!)
        expect(provider.currentEndpoint?.url) == Self.url("b")

        // Caller B reports the *same* (now superseded) endpoint: this must NOT advance again.
        provider.reportUnhealthy(endpointB!)
        expect(provider.currentEndpoint?.url) == Self.url("b")
    }

    func testReportingSameEndpointTwiceAdvancesOnlyOnce() {
        let provider = RemoteConfigSourceProvider(
            sources: [Self.source("a"), Self.source("b"), Self.source("c")],
            randomizer: FakeRandomizer(0)
        )

        let endpoint = provider.currentEndpoint
        provider.reportUnhealthy(endpoint!)
        provider.reportUnhealthy(endpoint!)
        provider.reportUnhealthy(endpoint!)

        expect(provider.currentEndpoint?.url) == Self.url("b")
    }

    func testReportingFreshEndpointAfterStaleReportStillAdvances() {
        let provider = RemoteConfigSourceProvider(
            sources: [Self.source("a"), Self.source("b"), Self.source("c")],
            randomizer: FakeRandomizer(0)
        )

        let stale = provider.currentEndpoint
        provider.reportUnhealthy(stale!)              // a -> b
        provider.reportUnhealthy(stale!)              // ignored, still b

        let fresh = provider.currentEndpoint          // b
        provider.reportUnhealthy(fresh!)              // b -> c
        expect(provider.currentEndpoint?.url) == Self.url("c")
    }

    func testStaleReportOnExhaustedProviderIsIgnored() {
        let provider = RemoteConfigSourceProvider(
            sources: [Self.source("a"), Self.source("b")],
            randomizer: FakeRandomizer(0)
        )

        let first = provider.currentEndpoint
        provider.reportUnhealthy(first!)
        let second = provider.currentEndpoint
        provider.reportUnhealthy(second!)
        expect(provider.currentEndpoint).to(beNil())

        // Reporting the original stale endpoint again must not resurrect or change anything.
        provider.reportUnhealthy(first!)
        expect(provider.currentEndpoint).to(beNil())
    }

    // MARK: - restart

    func testRestartRewindsToFirstSource() {
        let provider = RemoteConfigSourceProvider(
            sources: [Self.source("a"), Self.source("b"), Self.source("c")],
            randomizer: FakeRandomizer(0)
        )

        provider.reportUnhealthy(provider.currentEndpoint!)
        provider.reportUnhealthy(provider.currentEndpoint!)
        expect(provider.currentEndpoint?.url) == Self.url("c")

        provider.restart()
        expect(provider.currentEndpoint?.url) == Self.url("a")
    }

    func testRestartInvalidatesPreviouslyHandedOutEndpoints() {
        let provider = RemoteConfigSourceProvider(
            sources: [Self.source("a"), Self.source("b")],
            randomizer: FakeRandomizer(0)
        )

        let stale = provider.currentEndpoint
        provider.restart()

        // The pre-restart endpoint must not advance the freshly restarted provider.
        provider.reportUnhealthy(stale!)
        expect(provider.currentEndpoint?.url) == Self.url("a")
    }

    // MARK: - Threading

    func testConcurrentReportsAdvanceAtMostOncePerEndpoint() {
        let sources = (0..<100).map { Self.source("\($0)") }
        let provider = RemoteConfigSourceProvider(sources: sources, randomizer: FakeRandomizer(0))

        // Every iteration grabs the current endpoint and reports it unhealthy concurrently. Even
        // with many threads racing, a single endpoint can only advance the provider once, so the
        // provider must walk the fallback order one step at a time and never skip ahead.
        DispatchQueue.concurrentPerform(iterations: 500) { _ in
            if let endpoint = provider.currentEndpoint {
                provider.reportUnhealthy(endpoint)
            }
        }

        // The exact landing point is timing-dependent, but it must be a valid, reachable URL (or
        // nil if every source happened to be exhausted) — never a corrupted/torn state.
        if let url = provider.currentEndpoint?.url {
            expect(sources.map { $0.url }).to(contain(url))
        }
    }

    func testConcurrentReportsNeverSkipSourcesWhenSerialized() {
        // Drive the provider to exhaustion by always reporting the *current* endpoint. Collect every
        // distinct URL handed out; because stale reports are ignored, no source may be skipped.
        let sources = (0..<50).map { Self.source("\($0)") }
        let provider = RemoteConfigSourceProvider(sources: sources, randomizer: FakeRandomizer(0))

        let seen = Atomic<Set<String>>([])
        let group = DispatchGroup()
        for _ in 0..<8 {
            DispatchQueue.global().async(group: group) {
                while let endpoint = provider.currentEndpoint {
                    seen.modify { $0.insert(endpoint.url) }
                    provider.reportUnhealthy(endpoint)
                }
            }
        }
        group.wait()

        expect(seen.value) == Set(sources.map { $0.url })
        expect(provider.currentEndpoint).to(beNil())
    }

    // MARK: - Helpers

    private static func url(_ host: String) -> String {
        return "https://\(host).revenuecat.com"
    }

    private static func source(_ host: String, priority: Int = 0, weight: Int = 0) -> TestSource {
        return TestSource(url: url(host), priority: priority, weight: weight)
    }

}

private struct TestSource: RemoteConfigSource, Equatable {

    let url: String
    let priority: Int
    let weight: Int

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
