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

    func testCurrentApiSourceFallsBackToEmbeddedDefaultWhenTopicHasNoSources() {
        let provider = Self.provider(api: [], blob: [])
        expect(provider.getCurrent(for: .api)?.url) == "https://api.revenuecat.com"
        // Blob has no embedded default, so it stays empty.
        expect(provider.getCurrent(for: .blob)).to(beNil())
    }

    func testCurrentApiSourceFallsBackToEmbeddedDefaultWhenSourcesTopicAbsent() {
        let provider = RemoteConfigSourceProvider(
            topicStore: FakeTopicStore(nil),
            randomizer: FakeRandomizer(0)
        )
        expect(provider.getCurrent(for: .api)?.url) == "https://api.revenuecat.com"
        // Blob has no embedded default, so it stays empty.
        expect(provider.getCurrent(for: .blob)).to(beNil())
    }

    func testCurrentSourceReturnsHighestPrioritySource() {
        let low = Self.source("low", priority: 0, weight: 100)
        let high = Self.source("high", priority: 10, weight: 1)
        let provider = Self.apiProvider([low, high])

        let handle = provider.getCurrent(for: .api)
        expect(handle?.url) == Self.url("high")
        expect(handle?.purpose) == .api
    }

    func testCurrentSourceIsStableAcrossReads() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b")])

        expect(provider.getCurrent(for: .api)?.url) == provider.getCurrent(for: .api)?.url
    }

    // MARK: - reportUnhealthy advances

    func testReportUnhealthyAdvancesToNextSource() {
        let high = Self.source("high", priority: 10, weight: 1)
        let low = Self.source("low", priority: 0, weight: 1)
        let provider = Self.apiProvider([high, low])

        let first = provider.getCurrent(for: .api)
        expect(first?.url) == Self.url("high")

        provider.reportUnhealthy(first!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("low")
    }

    func testCurrentSourceIsNilWhenExhausted() {
        let provider = Self.apiProvider([Self.source("only")])

        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)).to(beNil())
    }

    func testReportUnhealthyWalksFullFallbackOrder() {
        let first = Self.source("1", priority: 30, weight: 1)
        let second = Self.source("2", priority: 20, weight: 1)
        let third = Self.source("3", priority: 10, weight: 1)
        let provider = Self.apiProvider([first, second, third])

        expect(provider.getCurrent(for: .api)?.url) == Self.url("1")
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("2")
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("3")
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)).to(beNil())
    }

    // MARK: - Dedup

    func testDedupsSourcesByURL() {
        let provider = Self.apiProvider([
            Self.source("a", priority: 10, weight: 1),
            Self.source("a", priority: 5, weight: 1),
            Self.source("b", priority: 0, weight: 1)
        ])

        expect(provider.getCurrent(for: .api)?.url) == Self.url("a")
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)).to(beNil())
    }

    func testDedupKeepsHighestPriorityRegardlessOfOrder() {
        let provider = Self.apiProvider([
            Self.source("a", priority: 0, weight: 1),
            Self.source("a", priority: 10, weight: 1),
            Self.source("b", priority: 5, weight: 1)
        ])

        // `a` is kept at priority 10, so it outranks `b` (priority 5) despite appearing first at 0.
        expect(provider.getCurrent(for: .api)?.url) == Self.url("a")
        expect(provider.getCurrent(for: .api)?.source.priority) == 10
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")
    }

    func testDedupTieBreaksByWeightForEqualPriority() {
        let provider = Self.apiProvider([
            Self.source("a", priority: 0, weight: 1),
            Self.source("a", priority: 0, weight: 100)
        ])

        expect(provider.getCurrent(for: .api)?.source.weight) == 100
    }

    // MARK: - api / blob independence

    func testAPIAndBlobAreExposedIndependently() {
        let provider = Self.provider(api: [Self.source("api")], blob: [Self.source("blob")])

        let api = provider.getCurrent(for: .api)
        let blob = provider.getCurrent(for: .blob)
        expect(api?.url) == Self.url("api")
        expect(api?.purpose) == .api
        expect(blob?.url) == Self.url("blob")
        expect(blob?.purpose) == .blob
    }

    func testReportingAPIUnhealthyDoesNotAffectBlob() {
        let provider = Self.provider(
            api: [Self.source("api1", priority: 10), Self.source("api2", priority: 0)],
            blob: [Self.source("blob1", priority: 10), Self.source("blob2", priority: 0)]
        )

        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("api2")
        expect(provider.getCurrent(for: .blob)?.url) == Self.url("blob1")

        provider.reportUnhealthy(provider.getCurrent(for: .blob)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("api2")
        expect(provider.getCurrent(for: .blob)?.url) == Self.url("blob2")
    }

    // MARK: - Stale report handling (race conditions)

    func testStaleReportIsIgnoredAfterAnotherCallerAdvanced() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        // Two callers grab the same current source.
        let handleA = provider.getCurrent(for: .api)
        let handleB = provider.getCurrent(for: .api)
        expect(handleA?.url) == handleB?.url

        // Caller A reports it unhealthy: the provider advances.
        provider.reportUnhealthy(handleA!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")

        // Caller B reports the *same* (now superseded) source: this must NOT advance again.
        provider.reportUnhealthy(handleB!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")
    }

    func testReportingSameSourceTwiceAdvancesOnlyOnce() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        let handle = provider.getCurrent(for: .api)
        provider.reportUnhealthy(handle!)
        provider.reportUnhealthy(handle!)
        provider.reportUnhealthy(handle!)

        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")
    }

    func testReportingFreshSourceAfterStaleReportStillAdvances() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        let stale = provider.getCurrent(for: .api)
        provider.reportUnhealthy(stale!)              // a -> b
        provider.reportUnhealthy(stale!)              // ignored, still b

        let fresh = provider.getCurrent(for: .api)       // b
        provider.reportUnhealthy(fresh!)              // b -> c
        expect(provider.getCurrent(for: .api)?.url) == Self.url("c")
    }

    func testStaleReportOnExhaustedProviderIsIgnored() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b")])

        let first = provider.getCurrent(for: .api)
        provider.reportUnhealthy(first!)
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)).to(beNil())

        // Reporting the original stale source again must not resurrect or change anything.
        provider.reportUnhealthy(first!)
        expect(provider.getCurrent(for: .api)).to(beNil())
    }

    // MARK: - restart

    func testRestartRewindsToFirstSource() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("c")

        provider.restart(for: .api)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("a")
    }

    func testRestartOnlyRewindsRequestedPurpose() {
        let provider = Self.provider(
            api: [Self.source("api1", priority: 10), Self.source("api2", priority: 0)],
            blob: [Self.source("blob1", priority: 10), Self.source("blob2", priority: 0)]
        )

        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        provider.reportUnhealthy(provider.getCurrent(for: .blob)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("api2")
        expect(provider.getCurrent(for: .blob)?.url) == Self.url("blob2")

        provider.restart(for: .api)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("api1")
        expect(provider.getCurrent(for: .blob)?.url) == Self.url("blob2")

        provider.restart(for: .blob)
        expect(provider.getCurrent(for: .blob)?.url) == Self.url("blob1")
    }

    func testStaleReportFromBeforeRestartIsIgnored() {
        let provider = Self.apiProvider([Self.source("a"), Self.source("b"), Self.source("c")])

        // A caller grabs `a`, then the provider is restarted before that caller reports back.
        let stale = provider.getCurrent(for: .api)
        expect(stale?.url) == Self.url("a")
        provider.restart(for: .api)

        // The stale report belongs to a pre-restart cycle, so it must not advance past `a`.
        provider.reportUnhealthy(stale!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("a")

        // A handle obtained after the restart still advances normally.
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")
    }

    // MARK: - Sources topic changes

    func testChangedSourcesTopicRebuildsAndRestartsFromTheTop() {
        let store = FakeTopicStore(Self.sourcesTopic(api: [Self.source("a"), Self.source("b")], blob: []))
        let provider = RemoteConfigSourceProvider(topicStore: store, randomizer: FakeRandomizer(0))

        provider.reportUnhealthy(provider.getCurrent(for: .api)!) // a -> b
        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")

        // The sources topic changes: the provider rebuilds and starts the new list from the top.
        store.sources = Self.sourcesTopic(api: [Self.source("x"), Self.source("y")], blob: [])
        expect(provider.getCurrent(for: .api)?.url) == Self.url("x")
    }

    func testUnchangedSourcesTopicPreservesFailoverProgress() {
        let store = FakeTopicStore(Self.sourcesTopic(api: [Self.source("a"), Self.source("b")], blob: []))
        let provider = RemoteConfigSourceProvider(topicStore: store, randomizer: FakeRandomizer(0))

        provider.reportUnhealthy(provider.getCurrent(for: .api)!) // a -> b

        // Re-providing content-equal sources must not rebuild, so the position is kept at `b`.
        store.sources = Self.sourcesTopic(api: [Self.source("a"), Self.source("b")], blob: [])
        expect(provider.getCurrent(for: .api)?.url) == Self.url("b")
    }

    func testStaleReportFromBeforeASourcesChangeIsIgnored() {
        let store = FakeTopicStore(
            Self.sourcesTopic(api: [Self.source("a"), Self.source("b"), Self.source("c")], blob: [])
        )
        let provider = RemoteConfigSourceProvider(topicStore: store, randomizer: FakeRandomizer(0))

        let stale = provider.getCurrent(for: .api)
        expect(stale?.url) == Self.url("a")

        // Sources change before the stale handle is reported back. Its report belongs to the old list, so
        // it must not advance the freshly-rebuilt one.
        store.sources = Self.sourcesTopic(api: [Self.source("x"), Self.source("y"), Self.source("z")], blob: [])
        provider.reportUnhealthy(stale!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("x")

        // A handle obtained after the change still advances normally.
        provider.reportUnhealthy(provider.getCurrent(for: .api)!)
        expect(provider.getCurrent(for: .api)?.url) == Self.url("y")
    }

    func testSourcesTopicAppearingAfterBeingAbsentReplacesTheEmbeddedDefaults() {
        let store = FakeTopicStore(nil)
        let provider = RemoteConfigSourceProvider(topicStore: store, randomizer: FakeRandomizer(0))

        expect(provider.getCurrent(for: .api)?.url) == "https://api.revenuecat.com"

        // A sources topic shows up where there was none: the provider builds the list from the top.
        store.sources = Self.sourcesTopic(api: [Self.source("a"), Self.source("b")], blob: [])
        expect(provider.getCurrent(for: .api)?.url) == Self.url("a")
    }

    // MARK: - Threading

    func testConcurrentReportsOfSameSourceAdvanceExactlyOnce() {
        let sources = (0..<100).map { Self.source("\($0)") }
        let provider = Self.apiProvider(sources)

        let first = provider.getCurrent(for: .api)
        expect(first?.url) == Self.url("0")

        // Many threads report the *same* source concurrently. The first report advances to the next
        // source; every other report now refers to a superseded url and must be ignored. So no matter
        // how the threads interleave, the provider advances exactly one step.
        DispatchQueue.concurrentPerform(iterations: 500) { _ in
            provider.reportUnhealthy(first!)
        }

        expect(provider.getCurrent(for: .api)?.url) == Self.url("1")
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
                while let handle = provider.getCurrent(for: .api) {
                    seen.modify { $0.insert(handle.url) }
                    provider.reportUnhealthy(handle)
                }
            }
        }
        group.wait()

        expect(seen.value) == Set(sources.map { $0.url })
        expect(provider.getCurrent(for: .api)).to(beNil())
    }

    // MARK: - Helpers

    private static func url(_ host: String) -> String {
        return "https://\(host).revenuecat.com"
    }

    private static func source(_ host: String, priority: Int = 0, weight: Int = 0) -> RemoteConfigSource {
        return RemoteConfigSource(url: url(host), priority: priority, weight: weight)
    }

    private static func apiProvider(_ sources: [RemoteConfigSource]) -> RemoteConfigSourceProvider {
        return provider(api: sources, blob: [])
    }

    private static func provider(
        api: [RemoteConfigSource],
        blob: [RemoteConfigSource]
    ) -> RemoteConfigSourceProvider {
        return RemoteConfigSourceProvider(
            topicStore: FakeTopicStore(sourcesTopic(api: api, blob: blob)),
            randomizer: FakeRandomizer(0)
        )
    }

    /// Builds a `sources` topic matching the backend shape: api entries use `url`, blob use `url_format`.
    private static func sourcesTopic(
        api: [RemoteConfigSource],
        blob: [RemoteConfigSource]
    ) -> RemoteConfiguration.ConfigTopic {
        func item(_ sources: [RemoteConfigSource], urlKey: String) -> RemoteConfiguration.ConfigItem {
            return RemoteConfiguration.ConfigItem(content: [
                "sources": .array(sources.map { source in
                    .object([
                        urlKey: .string(source.url),
                        "priority": .int(source.priority),
                        "weight": .int(source.weight)
                    ])
                })
            ])
        }
        return ["api": item(api, urlKey: "url"), "blob": item(blob, urlKey: "url_format")]
    }

}

private final class FakeTopicStore: RemoteConfigTopicStoreType {

    var sources: RemoteConfiguration.ConfigTopic?

    init(_ sources: RemoteConfiguration.ConfigTopic?) {
        self.sources = sources
    }

    func topic(_ name: String) -> RemoteConfiguration.ConfigTopic? {
        return name == "sources" ? self.sources : nil
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
