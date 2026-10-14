//
//  AdsInterstitialTests.swift
//
//  Created by RevenueCat.
//

import XCTest

#if os(iOS) && canImport(PrebidMobile)
@_spi(Experimental) @testable import RevenueCatAds

@MainActor
final class AdsInterstitialTests: TestCase {

    private var module: FakeAdModule!
    private var delegate: RecordingDelegate!
    private var interstitial: AdsInterstitial!

    override func setUp() async throws {
        try await super.setUp()
        self.module = FakeAdModule()
        self.delegate = RecordingDelegate()
        let module = self.module
        self.interstitial = AdsInterstitial(placementID: "placement", moduleProvider: { module })
        self.interstitial.delegate = self.delegate
    }

    // MARK: - Load

    func testLoadSucceedsAndNotifiesDelegate() async throws {
        try await self.loadSuccessfully()

        XCTAssertEqual(self.interstitial.state, .loaded)
        XCTAssertTrue(self.interstitial.isReady)
        XCTAssertEqual(self.module.lastInterstitial?.placementID, "placement")
        XCTAssertEqual(self.delegate.events, [.loaded])
    }

    func testLoadWaitsForAsynchronousModuleCallback() async throws {
        let task = Task { try await self.interstitial.load() }
        await self.waitUntil { self.module.lastInterstitial?.loadCallCount == 1 }
        XCTAssertEqual(self.interstitial.state, .loading)

        self.module.lastInterstitial?.emit(.loaded)
        try await task.value

        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testLoadFailureThrowsAndNotifiesDelegate() async {
        self.module.interstitialEvent = .failedToLoad(AdsError(code: .noFill, message: "none"))

        do {
            try await self.interstitial.load()
            XCTFail("Expected load to throw")
        } catch let error as AdsError {
            XCTAssertEqual(error.code, .noFill)
        } catch {
            XCTFail("Unexpected error \(error)")
        }

        XCTAssertEqual(self.interstitial.state, .idle)
        XCTAssertFalse(self.interstitial.isReady)
        XCTAssertEqual(self.delegate.events, [.failed(.noFill)])
    }

    func testLoadWithoutConfiguredModuleFailsWithNotConfigured() async {
        let interstitial = AdsInterstitial(placementID: "placement", moduleProvider: { nil })
        interstitial.delegate = self.delegate

        await XCTAssertThrowsAdsError(.notConfigured) { try await interstitial.load() }
        XCTAssertEqual(self.delegate.events, [.failed(.notConfigured)])
    }

    func testLoadWhileLoadingFailsWithInvalidState() async throws {
        let task = Task { try await self.interstitial.load() }
        await self.waitUntil { self.interstitial.state == .loading }

        await XCTAssertThrowsAdsError(.invalidState) { try await self.interstitial.load() }

        self.module.lastInterstitial?.emit(.loaded)
        try await task.value
        XCTAssertEqual(self.delegate.events, [.failed(.invalidState), .loaded])
    }

    func testCanReloadAfterFailure() async throws {
        self.module.interstitialEvent = .failedToLoad(AdsError(code: .loadFailed, message: "boom"))
        await XCTAssertThrowsAdsError(.loadFailed) { try await self.interstitial.load() }

        try await self.loadSuccessfully()

        XCTAssertEqual(self.module.interstitials.count, 2)
        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testCompletionLoadReportsError() async {
        self.module.interstitialEvent = .failedToLoad(AdsError(code: .noFill, message: "none"))

        let error: AdsError? = await withCheckedContinuation { continuation in
            self.interstitial.load { continuation.resume(returning: $0) }
        }

        XCTAssertEqual(error?.code, .noFill)
    }

    func testCompletionLoadReportsSuccess() async {
        self.module.interstitialEvent = .loaded

        let error: AdsError? = await withCheckedContinuation { continuation in
            self.interstitial.load { continuation.resume(returning: $0) }
        }

        XCTAssertNil(error)
        XCTAssertTrue(self.interstitial.isReady)
    }

    // MARK: - Present

    func testPresentBeforeLoadFailsWithNotReady() {
        self.interstitial.present(from: UIViewController())

        XCTAssertEqual(self.delegate.events, [.failed(.notReady)])
        XCTAssertEqual(self.interstitial.state, .idle)
    }

    func testPresentWhenModuleNotReadyFailsWithNotReady() async throws {
        try await self.loadSuccessfully()
        self.module.lastInterstitial?.isReady = false

        self.interstitial.present(from: UIViewController())

        XCTAssertEqual(self.module.lastInterstitial?.showCallCount, 0)
        XCTAssertEqual(self.delegate.events, [.loaded, .failed(.notReady)])
    }

    func testFullLifecycleDeliversEventsInOrder() async throws {
        try await self.loadSuccessfully()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        self.interstitial.present(from: UIViewController())
        XCTAssertEqual(unit.showCallCount, 1)
        XCTAssertEqual(self.interstitial.state, .presenting)

        unit.emit(.presented)
        unit.emit(.impression)
        unit.emit(.clicked)
        unit.emit(.dismissed)

        XCTAssertEqual(self.delegate.events, [.loaded, .presented, .impression, .clicked, .dismissed])
        XCTAssertEqual(self.interstitial.state, .idle)
        XCTAssertFalse(self.interstitial.isReady)
    }

    func testPresentTwiceOnlyShowsOnce() async throws {
        try await self.loadSuccessfully()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        self.interstitial.present(from: UIViewController())
        self.interstitial.present(from: UIViewController())

        XCTAssertEqual(unit.showCallCount, 1)
        XCTAssertEqual(self.delegate.events, [.loaded, .failed(.notReady)])
    }

    func testImpressionIsRecordedOnce() async throws {
        try await self.presentLoadedAd()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        unit.emit(.impression)
        unit.emit(.impression)

        XCTAssertEqual(self.delegate.events, [.loaded, .presented, .impression])
    }

    func testEventsOutsideTheirStateAreIgnored() async throws {
        try await self.loadSuccessfully()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        unit.emit(.loaded)
        unit.emit(.failedToLoad(AdsError(code: .loadFailed, message: "late")))
        unit.emit(.presented)
        unit.emit(.impression)
        unit.emit(.clicked)
        unit.emit(.dismissed)

        XCTAssertEqual(self.delegate.events, [.loaded])
        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testCanLoadAgainAfterDismissal() async throws {
        try await self.presentLoadedAd()
        self.module.lastInterstitial?.emit(.dismissed)

        try await self.loadSuccessfully()

        XCTAssertEqual(self.module.interstitials.count, 2)
        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testLoadWhilePresentedFailsWithInvalidState() async throws {
        try await self.presentLoadedAd()

        await XCTAssertThrowsAdsError(.invalidState) { try await self.interstitial.load() }
    }

    // MARK: - Helpers

    private func loadSuccessfully() async throws {
        self.module.interstitialEvent = .loaded
        try await self.interstitial.load()
    }

    private func presentLoadedAd() async throws {
        try await self.loadSuccessfully()
        self.interstitial.present(from: UIViewController())
        self.module.lastInterstitial?.emit(.presented)
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1_000 where !condition() {
            await Task.yield()
        }
        XCTAssertTrue(condition(), "Condition not met")
    }

}

@MainActor
private func XCTAssertThrowsAdsError(
    _ code: AdsError.Code,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ body: () async throws -> Void
) async {
    do {
        try await body()
        XCTFail("Expected AdsError \(code)", file: file, line: line)
    } catch let error as AdsError {
        XCTAssertEqual(error.code, code, file: file, line: line)
    } catch {
        XCTFail("Unexpected error \(error)", file: file, line: line)
    }
}

#endif
