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
    private var tracking: FakeAdTracking!
    private var delegate: RecordingDelegate!
    private var interstitial: AdsInterstitial!
    private var presenters: PresenterFactory!

    override func setUp() async throws {
        try await super.setUp()
        self.presenters = PresenterFactory()
        self.module = FakeAdModule()
        self.tracking = FakeAdTracking()
        self.delegate = RecordingDelegate()
        let module = self.module
        self.interstitial = AdsInterstitial(
            placementID: "placement",
            moduleProvider: { module },
            tracking: self.tracking
        )
        self.interstitial.delegate = self.delegate
    }

    // MARK: - Load

    func testLoadSucceedsWithoutInvolvingTheDelegate() async throws {
        try await self.loadSuccessfully()

        XCTAssertEqual(self.interstitial.state, .loaded)
        XCTAssertTrue(self.interstitial.isReady)
        XCTAssertEqual(self.module.lastInterstitial?.placementID, "placement")
        XCTAssertEqual(self.delegate.events, [])
    }

    func testLoadWaitsForAsynchronousModuleCallback() async throws {
        let task = Task { try await self.interstitial.load() }
        await self.waitUntil { self.module.lastInterstitial?.loadCallCount == 1 }
        XCTAssertEqual(self.interstitial.state, .loading)

        self.module.lastInterstitial?.emit(.loaded)
        try await task.value

        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testLoadFailureThrowsWithoutInvolvingTheDelegate() async {
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
        XCTAssertEqual(self.delegate.events, [])
    }

    func testLoadWithoutConfiguredModuleFailsWithNotConfigured() async {
        let interstitial = AdsInterstitial(
            placementID: "placement",
            moduleProvider: { nil },
            tracking: FakeAdTracking()
        )
        interstitial.delegate = self.delegate

        await XCTAssertThrowsAdsError(.notConfigured) { try await interstitial.load() }
        XCTAssertEqual(self.delegate.events, [])
    }

    func testLoadWhileLoadedKeepsTheCurrentAd() async throws {
        try await self.loadSuccessfully()

        try await self.interstitial.load()

        XCTAssertEqual(self.module.interstitials.count, 1)
        XCTAssertEqual(self.interstitial.state, .loaded)
        XCTAssertEqual(self.delegate.events, [])
    }

    func testLoadWhileLoadingFailsWithInvalidState() async throws {
        let task = Task { try await self.interstitial.load() }
        await self.waitUntil { self.interstitial.state == .loading }

        await XCTAssertThrowsAdsError(.invalidState) { try await self.interstitial.load() }

        self.module.lastInterstitial?.emit(.loaded)
        try await task.value
        XCTAssertEqual(self.delegate.events, [])
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
        self.interstitial.present(from: self.presenters.makePresenter())

        XCTAssertEqual(self.delegate.events, [.failedToPresent(.notReady)])
        XCTAssertEqual(self.interstitial.state, .idle)
    }

    func testPresentWhenModuleNotReadyFailsWithNotReady() async throws {
        try await self.loadSuccessfully()
        self.module.lastInterstitial?.isReady = false

        self.interstitial.present(from: self.presenters.makePresenter())

        XCTAssertEqual(self.module.lastInterstitial?.showCallCount, 0)
        XCTAssertEqual(self.delegate.events, [.failedToPresent(.notReady)])
    }

    func testPresentFromViewControllerWithoutWindowFailsAndKeepsAd() async throws {
        try await self.loadSuccessfully()

        self.interstitial.present(from: UIViewController())

        XCTAssertEqual(self.module.lastInterstitial?.showCallCount, 0)
        XCTAssertEqual(self.delegate.events, [.failedToPresent(.presentFailed)])
        XCTAssertEqual(self.interstitial.state, .loaded)
        XCTAssertTrue(self.interstitial.isReady)
    }

    func testPresentFromViewControllerAlreadyPresentingFailsAndKeepsAd() async throws {
        try await self.loadSuccessfully()
        let presenter = self.presenters.makePresenter()
        presenter.present(UIViewController(), animated: false)

        self.interstitial.present(from: presenter)

        XCTAssertEqual(self.module.lastInterstitial?.showCallCount, 0)
        XCTAssertEqual(self.delegate.events, [.failedToPresent(.presentFailed)])
        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testRefusedPresentationFailsDiscardsAdAndAllowsReload() async throws {
        try await self.loadSuccessfully()
        let unit = try XCTUnwrap(self.module.lastInterstitial)
        unit.presentsOnShow = false

        self.interstitial.present(from: self.presenters.makePresenter())
        unit.emit(.presented)
        unit.emit(.impression)
        XCTAssertEqual(self.delegate.events, [])
        await self.waitUntil { self.interstitial.state == .idle }

        XCTAssertEqual(self.delegate.events, [.failedToPresent(.presentFailed)])
        XCTAssertEqual(self.tracking.trackedEventCount, 1, "Only the load is tracked")
        try await self.loadSuccessfully()
        XCTAssertEqual(self.module.interstitials.count, 2)
    }

    func testCanPresentAfterFailedPresentation() async throws {
        try await self.loadSuccessfully()
        self.interstitial.present(from: UIViewController())

        self.interstitial.present(from: self.presenters.makePresenter())

        XCTAssertEqual(self.module.lastInterstitial?.showCallCount, 1)
        XCTAssertEqual(self.interstitial.state, .presenting)
    }

    func testFullLifecycleDeliversEventsInOrder() async throws {
        try await self.loadSuccessfully()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        self.interstitial.present(from: self.presenters.makePresenter())
        XCTAssertEqual(unit.showCallCount, 1)
        XCTAssertEqual(self.interstitial.state, .presenting)

        unit.emit(.presented)
        unit.emit(.impression)
        XCTAssertEqual(self.delegate.events, [], "Nothing is reported until UIKit's answer is known")
        await self.waitUntil { self.interstitial.state == .presented }
        unit.emit(.clicked)
        unit.emit(.dismissed)

        XCTAssertEqual(self.delegate.events, [.presented, .impression, .clicked, .dismissed])
        XCTAssertEqual(self.interstitial.state, .idle)
        XCTAssertFalse(self.interstitial.isReady)
        XCTAssertEqual(self.tracking.displayed.count, 1)
    }

    func testPresentTwiceOnlyShowsOnce() async throws {
        try await self.loadSuccessfully()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        self.interstitial.present(from: self.presenters.makePresenter())
        self.interstitial.present(from: self.presenters.makePresenter())

        XCTAssertEqual(unit.showCallCount, 1)
        XCTAssertEqual(self.delegate.events, [.failedToPresent(.notReady)])
    }

    func testImpressionIsRecordedOnce() async throws {
        try await self.presentLoadedAd()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        unit.emit(.impression)
        unit.emit(.impression)

        XCTAssertEqual(self.delegate.events, [.presented, .impression])
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

        XCTAssertEqual(self.delegate.events, [])
        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testExpiryResetsAndCanLoadAgain() async throws {
        try await self.loadSuccessfully()

        self.module.lastInterstitial?.emit(.expired)
        XCTAssertEqual(self.interstitial.state, .idle)
        XCTAssertFalse(self.interstitial.isReady)

        try await self.loadSuccessfully()

        XCTAssertEqual(self.delegate.events, [.expired])
        XCTAssertEqual(self.module.interstitials.count, 2)
    }

    func testEventsFromReplacedUnitAreIgnored() async throws {
        try await self.presentLoadedAd()
        let oldUnit = try XCTUnwrap(self.module.lastInterstitial)
        oldUnit.emit(.dismissed)
        try await self.loadSuccessfully()

        oldUnit.emit(.expired)
        oldUnit.emit(.dismissed)

        XCTAssertEqual(self.delegate.events, [.presented, .dismissed])
        XCTAssertEqual(self.interstitial.state, .loaded)
    }

    func testExpiryWhilePresentedIsIgnored() async throws {
        try await self.presentLoadedAd()

        self.module.lastInterstitial?.emit(.expired)

        XCTAssertEqual(self.delegate.events, [.presented])
        XCTAssertEqual(self.interstitial.state, .presented)
    }

    func testPresentingAdOutlivesTheCallersReference() async throws {
        self.module.interstitialEvent = .loaded
        weak var weakInterstitial: AdsInterstitial?
        try await {
            let interstitial = AdsInterstitial(
                placementID: "placement",
                moduleProvider: { [module] in module },
                tracking: FakeAdTracking()
            )
            interstitial.delegate = self.delegate
            weakInterstitial = interstitial
            try await interstitial.load()
            interstitial.present(from: self.presenters.makePresenter())
        }()
        let unit = try XCTUnwrap(self.module.lastInterstitial)

        XCTAssertNotNil(weakInterstitial, "The interstitial must stay alive until its ad is dismissed")
        unit.emit(.presented)
        await self.waitUntil { weakInterstitial?.state == .presented }
        unit.emit(.dismissed)

        XCTAssertEqual(self.delegate.events, [.presented, .dismissed])
        XCTAssertNil(weakInterstitial, "The interstitial must be released once its ad is dismissed")
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
}

// MARK: - Helpers

private extension AdsInterstitialTests {

    func loadSuccessfully() async throws {
        self.module.interstitialEvent = .loaded
        try await self.interstitial.load()
    }

    func presentLoadedAd() async throws {
        try await self.loadSuccessfully()
        self.interstitial.present(from: self.presenters.makePresenter())
        self.module.lastInterstitial?.emit(.presented)
        await self.waitUntil { self.interstitial.state == .presented }
    }

    func waitUntil(_ condition: () -> Bool) async {
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
