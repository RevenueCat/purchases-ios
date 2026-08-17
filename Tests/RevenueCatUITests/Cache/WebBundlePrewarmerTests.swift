//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundlePrewarmerTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/17/26.

@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class WebBundlePrewarmerTests: TestCase {

    func testEmptySetDoesNotCallLoad() async {
        let probe = LoadProbe()
        let prewarmer = WebBundlePrewarmer { url in
            await probe.load(url)
        }

        await prewarmer.prewarm([])

        let loaded = await probe.loaded
        XCTAssertTrue(loaded.isEmpty)
    }

    func testLoadsEveryURLInTheBatch() async {
        let probe = LoadProbe()
        let prewarmer = WebBundlePrewarmer { url in
            await probe.load(url)
        }
        let urls = Self.urls("https://example.com/a", "https://example.com/b", "https://example.com/c")

        await prewarmer.prewarm(urls)

        let loaded = await probe.loaded
        XCTAssertEqual(Set(loaded), Set(urls.map(\.url)))
        XCTAssertEqual(loaded.count, urls.count)
    }

    func testDuplicateURLsInASetLoadOnce() async {
        let probe = LoadProbe()
        let prewarmer = WebBundlePrewarmer { url in
            await probe.load(url)
        }
        let url = Self.url("https://example.com/a")

        await prewarmer.prewarm([
            .init(url: url, checksum: nil),
            .init(url: url, checksum: nil)
        ])

        let loaded = await probe.loaded
        XCTAssertEqual(loaded, [url])
    }

    func testDoesNotExceedMaxConcurrentLoads() async throws {
        let probe = LoadProbe(gated: true)
        let prewarmer = WebBundlePrewarmer(maxConcurrentLoads: 2) { url in
            await probe.load(url)
        }
        let urls = Self.urls(
            "https://example.com/a",
            "https://example.com/b",
            "https://example.com/c"
        )

        let task = Task {
            await prewarmer.prewarm(urls)
        }

        try await asyncWait(description: "first two loads started") {
            await probe.startedCount == 2
        }
        let startedAfterTwo = await probe.startedCount
        let maxAfterTwo = await probe.maxInFlight
        XCTAssertEqual(startedAfterTwo, 2)
        XCTAssertEqual(maxAfterTwo, 2)

        await probe.releaseOne()

        try await asyncWait(description: "third load started") {
            await probe.startedCount == 3
        }
        let maxAfterThree = await probe.maxInFlight
        XCTAssertEqual(maxAfterThree, 2)

        await probe.releaseAll()
        await task.value
    }

    func testALoadThatReturnsEarlyDoesNotCancelTheRestOfTheBatch() async {
        let probe = LoadProbe()
        let early = Self.url("https://example.com/a")
        let prewarmer = WebBundlePrewarmer(maxConcurrentLoads: 1) { url in
            if url == early { return }
            await probe.load(url)
        }
        let urls = Self.urls("https://example.com/a", "https://example.com/b")

        await prewarmer.prewarm(urls)

        let loaded = await probe.loaded
        XCTAssertEqual(loaded, [Self.url("https://example.com/b")])
        XCTAssertEqual(loaded.count, 1)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension WebBundlePrewarmerTests {

    static func urls(_ strings: String...) -> Set<URLWithValidation> {
        return Set(strings.map { .init(url: self.url($0), checksum: nil) })
    }

    static func url(_ string: String) -> URL {
        // swiftlint:disable:next force_unwrapping
        return URL(string: string)!
    }

}

/// Records load calls without constructing a `WKWebView`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private actor LoadProbe {

    private(set) var loaded: [URL] = []
    private(set) var startedCount = 0
    private(set) var maxInFlight = 0

    private var inFlight = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let gated: Bool

    init(gated: Bool = false) {
        self.gated = gated
    }

    func load(_ url: URL) async {
        self.startedCount += 1
        self.inFlight += 1
        self.maxInFlight = max(self.maxInFlight, self.inFlight)

        if self.gated {
            await withCheckedContinuation { continuation in
                self.waiters.append(continuation)
            }
        }

        self.inFlight = max(self.inFlight - 1, 0)
        self.loaded.append(url)
    }

    func releaseOne() {
        guard !self.waiters.isEmpty else { return }
        self.waiters.removeFirst().resume()
    }

    func releaseAll() {
        let waiters = self.waiters
        self.waiters.removeAll()
        waiters.forEach { $0.resume() }
    }

}
