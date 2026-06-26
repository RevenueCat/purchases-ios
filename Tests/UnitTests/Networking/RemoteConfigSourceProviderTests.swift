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

    func testCurrentSourcesAreNilWhenNoSources() {
        let provider = RemoteConfigSourceProvider(
            sources: RemoteConfigSources(api: [], blob: []),
            randomizer: FakeRandomizer()
        )
        expect(provider.currentAPISource).to(beNil())
        expect(provider.currentBlobSource).to(beNil())
    }

    func testCurrentSourceReturnsHighestPrioritySource() {
        let low = Self.source("low", priority: 0, weight: 100)
        let high = Self.source("high", priority: 10, weight: 1)
        let provider = Self.apiProvider([low, high])

        let handle = provider.currentAPISource
        expect(handle?.url) == Self.url("high")
        expect(handle?.purpose) == .api
    }

    func testCurrentSourceIsStableAcrossReads() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b")])

        expect(provider.currentAPISource?.url) == provider.currentAPISource?.url
    }

    // MARK: - reportUnhealthy advances

    func testReportUnhealthyAdvancesToNextSource() {
        let high = Self.source("high", priority: 10, weight: 1)
        let low = Self.source("low", priority: 0, weight: 1)
        let provider = Self.apiProvider([high, low])

        let first = provider.currentAPISource
        expect(first?.url) == Self.url("high")

        provider.reportUnhealthy(first!)
        expect(provider.currentAPISource?.url) == Self.url("low")
    }

    func testCurrentSourceIsNilWhenExhausted() {
        let provider = Self.apiProvider([Self.source("only")])

        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource).to(beNil())
    }

    func testReportUnhealthyWalksFullFallbackOrder() {
        let first = Self.source("1", priority: 30, weight: 1)
        let second = Self.source("2", priority: 20, weight: 1)
        let third = Self.source("3", priority: 10, weight: 1)
        let provider = Self.apiProvider([first, second, third])

        expect(provider.currentAPISource?.url) == Self.url("1")
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource?.url) == Self.url("2")
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource?.url) == Self.url("3")
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource).to(beNil())
    }

    // MARK: - Dedup

    func testDedupsSourcesByURL() {
        let provider = Self.apiProvider([
            Self.source("a", priority: 10, weight: 1),
            Self.source("a", priority: 5, weight: 1),
            Self.source("b", priority: 0, weight: 1)
        ])

        expect(provider.currentAPISource?.url) == Self.url("a")
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource?.url) == Self.url("b")
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource).to(beNil())
    }

    func testDedupKeepsHighestPriorityRegardlessOfOrder() {
        let provider = Self.apiProvider([
            Self.source("a", priority: 0, weight: 1),
            Self.source("a", priority: 10, weight: 1),
            Self.source("b", priority: 5, weight: 1)
        ])

        // `a` is kept at priority 10, so it outranks `b` (priority 5) despite appearing first at 0.
        expect(provider.currentAPISource?.url) == Self.url("a")
        expect(provider.currentAPISource?.priority) == 10
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource?.url) == Self.url("b")
    }

    func testDedupTieBreaksByWeightForEqualPriority() {
        let provider = Self.apiProvider([
            Self.source("a", priority: 0, weight: 1),
            Self.source("a", priority: 0, weight: 100)
        ])

        expect(provider.currentAPISource?.weight) == 100
    }

    // MARK: - api / blob independence

    func testAPIAndBlobAreExposedIndependently() {
        let provider = RemoteConfigSourceProvider(
            sources: RemoteConfigSources(api: [Self.source("api")], blob: [Self.source("blob")]),
            randomizer: FakeRandomizer(0)
        )

        let api = provider.currentAPISource
        let blob = provider.currentBlobSource
        expect(api?.url) == Self.url("api")
        expect(api?.purpose) == .api
        expect(blob?.url) == Self.url("blob")
        expect(blob?.purpose) == .blob
    }

    func testReportingAPIUnhealthyDoesNotAffectBlob() {
        let provider = RemoteConfigSourceProvider(
            sources: RemoteConfigSources(
                api: [Self.source("api1", priority: 10), Self.source("api2", priority: 0)],
                blob: [Self.source("blob1", priority: 10), Self.source("blob2", priority: 0)]
            ),
            randomizer: FakeRandomizer(0)
        )

        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource?.url) == Self.url("api2")
        expect(provider.currentBlobSource?.url) == Self.url("blob1")

        provider.reportUnhealthy(provider.currentBlobSource!)
        expect(provider.currentAPISource?.url) == Self.url("api2")
        expect(provider.currentBlobSource?.url) == Self.url("blob2")
    }

    // MARK: - Stale report handling (race conditions)

    func testStaleReportIsIgnoredAfterAnotherCallerAdvanced() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        // Two callers grab the same current source.
        let handleA = provider.currentAPISource
        let handleB = provider.currentAPISource
        expect(handleA?.url) == handleB?.url

        // Caller A reports it unhealthy: the provider advances.
        provider.reportUnhealthy(handleA!)
        expect(provider.currentAPISource?.url) == Self.url("b")

        // Caller B reports the *same* (now superseded) source: this must NOT advance again.
        provider.reportUnhealthy(handleB!)
        expect(provider.currentAPISource?.url) == Self.url("b")
    }

    func testReportingSameSourceTwiceAdvancesOnlyOnce() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        let handle = provider.currentAPISource
        provider.reportUnhealthy(handle!)
        provider.reportUnhealthy(handle!)
        provider.reportUnhealthy(handle!)

        expect(provider.currentAPISource?.url) == Self.url("b")
    }

    func testReportingFreshSourceAfterStaleReportStillAdvances() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        let stale = provider.currentAPISource
        provider.reportUnhealthy(stale!)              // a -> b
        provider.reportUnhealthy(stale!)              // ignored, still b

        let fresh = provider.currentAPISource       // b
        provider.reportUnhealthy(fresh!)              // b -> c
        expect(provider.currentAPISource?.url) == Self.url("c")
    }

    func testStaleReportOnExhaustedProviderIsIgnored() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b")])

        let first = provider.currentAPISource
        provider.reportUnhealthy(first!)
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource).to(beNil())

        // Reporting the original stale source again must not resurrect or change anything.
        provider.reportUnhealthy(first!)
        expect(provider.currentAPISource).to(beNil())
    }

    // MARK: - restart

    func testRestartRewindsToFirstSource() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        provider.reportUnhealthy(provider.currentAPISource!)
        provider.reportUnhealthy(provider.currentAPISource!)
        expect(provider.currentAPISource?.url) == Self.url("c")

        provider.restart(for: .api)
        expect(provider.currentAPISource?.url) == Self.url("a")
    }

    func testRestartOnlyRewindsRequestedPurpose() {
        let provider = RemoteConfigSourceProvider(
            sources: RemoteConfigSources(
                api: [Self.source("api1", priority: 10), Self.source("api2", priority: 0)],
                blob: [Self.source("blob1", priority: 10), Self.source("blob2", priority: 0)]
            ),
            randomizer: FakeRandomizer(0)
        )

        provider.reportUnhealthy(provider.currentAPISource!)
        provider.reportUnhealthy(provider.currentBlobSource!)
        expect(provider.currentAPISource?.url) == Self.url("api2")
        expect(provider.currentBlobSource?.url) == Self.url("blob2")

        provider.restart(for: .api)
        expect(provider.currentAPISource?.url) == Self.url("api1")
        expect(provider.currentBlobSource?.url) == Self.url("blob2")

        provider.restart(for: .blob)
        expect(provider.currentBlobSource?.url) == Self.url("blob1")
    }

    // MARK: - Threading

    func testConcurrentReportsOfSameSourceAdvanceExactlyOnce() {
        let sources = (0..<100).map { Self.source("\($0)") }
        let provider = Self.apiProvider(sources)

        let first = provider.currentAPISource
        expect(first?.url) == Self.url("0")

        // Many threads report the *same* source concurrently. The first report advances to the next
        // source; every other report now refers to a superseded url and must be ignored. So no matter
        // how the threads interleave, the provider advances exactly one step.
        DispatchQueue.concurrentPerform(iterations: 500) { _ in
            provider.reportUnhealthy(first!)
        }

        expect(provider.currentAPISource?.url) == Self.url("1")
    }

    func testConcurrentReportsNeverSkipSourcesWhenSerialized() {
        // Drive the provider to exhaustion by always reporting the *current* source. Collect every
        // distinct URL handed out; because stale reports are ignored, no source may be skipped.
        let sources = (0..<50).map { Self.source("\($0)") }
        let provider = Self.apiProvider(sources)

        let seen = Atomic<Set<String>>([])
        let group = DispatchGroup()
        for _ in 0..<8 {
            DispatchQueue.global().async(group: group) {
                while let handle = provider.currentAPISource {
                    seen.modify { $0.insert(handle.url) }
                    provider.reportUnhealthy(handle)
                }
            }
        }
        group.wait()

        expect(seen.value) == Set(sources.map { $0.url })
        expect(provider.currentAPISource).to(beNil())
    }

    // MARK: - Helpers

    private static func url(_ host: String) -> String {
        return "https://\(host).revenuecat.com"
    }

    private static func source(_ host: String, priority: Int = 0, weight: Int = 0) -> RemoteConfigSource {
        return RemoteConfigSource(url: url(host), priority: priority, weight: weight)
    }

    private static func apiProvider(_ sources: [RemoteConfigSource]) -> RemoteConfigSourceProvider {
        return RemoteConfigSourceProvider(
            sources: RemoteConfigSources(api: sources, blob: []),
            randomizer: FakeRandomizer(0)
        )
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
