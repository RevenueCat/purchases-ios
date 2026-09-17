import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) @testable import RevenueCatAdMob
@_spi(CheckpointsInternal) import RevenueCatUI

@available(iOS 15.0, *)
@MainActor
final class AdMobPresenterTests: AdapterTestCase {

    private let loaders = FormatLoaders()
    private lazy var presenter: AdMobPresenter = {
        let loaders = self.loaders
        return AdMobPresenter(
            makeInterstitialPresentation: {
                InterstitialPresentation(
                    loadAd: loaders.loadInterstitial,
                    presentingViewControllerProvider: { UIViewController() }
                )
            },
            makeRewardedPresentation: { format in
                RewardedPresentation(
                    format: format,
                    loadAd: loaders.loadRewarded(format),
                    presentingViewControllerProvider: { UIViewController() }
                )
            }
        )
    }()

    // MARK: - Dispatch by format

    func testInterstitialFormatLoadsThroughTheInterstitialLoader() {
        let loaded = self.expectation(description: "loaded")
        self.loaders.onLoad = { loaded.fulfill() }

        self.presenter.present(params: Self.params(adFormat: .interstitial)) { _ in }
        self.wait(for: [loaded], timeout: 2.0)

        XCTAssertEqual(self.loaders.requests, [.interstitial(adUnitID: "ad-unit", placement: "checkpoint_id")])
    }

    func testRewardedFormatLoadsThroughTheRewardedLoader() {
        let loaded = self.expectation(description: "loaded")
        self.loaders.onLoad = { loaded.fulfill() }

        self.presenter.present(params: Self.params(adFormat: .rewarded)) { _ in }
        self.wait(for: [loaded], timeout: 2.0)

        XCTAssertEqual(self.loaders.requests, [.rewarded(adUnitID: "ad-unit", placement: "checkpoint_id")])
    }

    func testRewardedInterstitialFormatLoadsThroughTheRewardedInterstitialLoader() {
        let loaded = self.expectation(description: "loaded")
        self.loaders.onLoad = { loaded.fulfill() }

        self.presenter.present(params: Self.params(adFormat: .rewardedInterstitial)) { _ in }
        self.wait(for: [loaded], timeout: 2.0)

        XCTAssertEqual(
            self.loaders.requests,
            [.rewardedInterstitial(adUnitID: "ad-unit", placement: "checkpoint_id")]
        )
    }

    func testUsesTheStepPlacementAsThePlacement() {
        let loaded = self.expectation(description: "loaded")
        self.loaders.onLoad = { loaded.fulfill() }

        self.presenter.present(
            params: Self.params(
                checkpointIdentifier: "level_complete",
                adFormat: .interstitial,
                placement: "between_levels"
            )
        ) { _ in }
        self.wait(for: [loaded], timeout: 2.0)

        XCTAssertEqual(self.loaders.requests, [.interstitial(adUnitID: "ad-unit", placement: "between_levels")])
    }

    func testFallsBackToTheCheckpointIdentifierAsThePlacement() {
        let loaded = self.expectation(description: "loaded")
        self.loaders.onLoad = { loaded.fulfill() }

        self.presenter.present(
            params: Self.params(checkpointIdentifier: "level_complete", adFormat: .interstitial)
        ) { _ in }
        self.wait(for: [loaded], timeout: 2.0)

        XCTAssertEqual(self.loaders.requests, [.interstitial(adUnitID: "ad-unit", placement: "level_complete")])
    }

    func testForwardsTheMediatorSoNonAdMobStepsFailWithoutLoading() {
        var results: [AdPresentationResult] = []

        self.presenter.present(params: Self.params(adFormat: .interstitial, mediator: .appLovin)) { result in
            results.append(result)
        }

        XCTAssertEqual(results.count, 1)
        XCTAssertNotEqual(results[0], AdPresentationResult.shown)
        XCTAssertTrue(self.loaders.requests.isEmpty)
    }

    // MARK: - Unsupported formats

    func testUnsupportedFormatFailsImmediatelyWithoutLoadingAnything() {
        var results: [AdPresentationResult] = []

        let formats = [RevenueCat.AdFormat.banner, .native, .appOpen, .other, .init(rawValue: "some_future_format")]
        for format in formats {
            self.presenter.present(params: Self.params(adFormat: format)) { result in
                results.append(result)
            }
        }

        XCTAssertEqual(results.count, 5)
        for result in results {
            XCTAssertNotEqual(result, AdPresentationResult.shown)
            XCTAssertNotEqual(result, AdPresentationResult.rewardVerificationFailed)
        }
        XCTAssertTrue(self.loaders.requests.isEmpty)
    }

    func testUnsupportedFormatErrorDescribesTheFormatAndTheSupportedOnes() {
        let error = AdMobPresentationError.unsupportedFormat("banner") as NSError

        XCTAssertEqual(error.domain, "RevenueCatAdMob.AdMobPresentationError")
        XCTAssertEqual(error.code, 1)
        XCTAssertTrue(error.localizedDescription.contains("'banner'"))
        XCTAssertTrue(error.localizedDescription.contains("rewarded_interstitial"))
    }

    // MARK: - Outcome forwarding

    func testInterstitialDismissalCompletesWithShown() throws {
        let presented = self.expectation(description: "presented")
        self.loaders.interstitialAd.onPresent = { presented.fulfill() }
        var results: [AdPresentationResult] = []

        self.presenter.present(params: Self.params(adFormat: .interstitial)) { result in
            results.append(result)
        }
        self.wait(for: [presented], timeout: 2.0)

        let delegate = try XCTUnwrap(self.loaders.lastDelegate)
        delegate.adDidDismissFullScreenContent?(PresentingAdStub())

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0], AdPresentationResult.shown)
    }

    func testLoadFailureCompletesWithFailed() {
        self.loaders.loadError = NSError(domain: "gma", code: 1)
        let completed = self.expectation(description: "completed")
        var results: [AdPresentationResult] = []

        self.presenter.present(params: Self.params(adFormat: .rewarded)) { result in
            results.append(result)
            completed.fulfill()
        }
        self.wait(for: [completed], timeout: 2.0)

        XCTAssertEqual(results.count, 1)
        XCTAssertNotEqual(results[0], AdPresentationResult.shown)
    }

    func testBackToBackPresentationsOfDifferentFormatsEachCompleteIndependently() throws {
        var results: [AdPresentationResult] = []

        for format in [RevenueCat.AdFormat.interstitial, .rewarded, .interstitial] {
            let loaded = self.expectation(description: "loaded \(format.rawValue)")
            self.loaders.onLoad = { loaded.fulfill() }
            let presented = self.expectation(description: "presented \(format.rawValue)")
            self.loaders.interstitialAd.onPresent = { presented.fulfill() }
            self.loaders.rewardedAd.onPresent = { presented.fulfill() }

            self.presenter.present(params: Self.params(adFormat: format)) { result in
                results.append(result)
            }
            self.wait(for: [loaded, presented], timeout: 2.0)

            let delegate = try XCTUnwrap(self.loaders.lastDelegate)
            delegate.adDidDismissFullScreenContent?(PresentingAdStub())
        }

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0 == AdPresentationResult.shown })
        XCTAssertEqual(self.loaders.requests.map(\.formatName), ["interstitial", "rewarded", "interstitial"])
    }

    // MARK: - Helpers

    private static func params(
        checkpointIdentifier: String = "checkpoint_id",
        adFormat: RevenueCat.AdFormat,
        mediator: MediatorName = .adMob,
        placement: String? = nil
    ) -> AdPresentationParams {
        return AdPresentationParams(
            checkpointIdentifier: checkpointIdentifier,
            adIdentifier: "ad-unit",
            mediator: mediator,
            adFormat: adFormat,
            placement: placement
        )
    }

}

// MARK: - Test doubles

/// Records which format-specific loader the presenter routed each request through.
@available(iOS 15.0, *)
@MainActor
private final class FormatLoaders {

    enum Request: Equatable {
        case interstitial(adUnitID: String, placement: String)
        case rewarded(adUnitID: String, placement: String)
        case rewardedInterstitial(adUnitID: String, placement: String)

        var formatName: String {
            switch self {
            case .interstitial: return "interstitial"
            case .rewarded: return "rewarded"
            case .rewardedInterstitial: return "rewarded_interstitial"
            }
        }
    }

    private(set) var requests: [Request] = []
    private(set) weak var lastDelegate: GoogleMobileAds.FullScreenContentDelegate?
    var onLoad: (() -> Void)?
    var loadError: Error?

    let interstitialAd = FakeInterstitialAd()
    let rewardedAd = FakeRewardedAd()

    func loadInterstitial(
        adUnitID: String,
        placement: String,
        delegate: GoogleMobileAds.FullScreenContentDelegate
    ) throws -> any InterstitialPresentableAd {
        self.record(.interstitial(adUnitID: adUnitID, placement: placement), delegate: delegate)
        if let loadError { throw loadError }
        return self.interstitialAd
    }

    func loadRewarded(_ format: RewardedPresentation.Format) -> RewardedPresentation.LoadAd {
        return { adUnitID, placement, delegate in
            switch format {
            case .rewarded:
                self.record(.rewarded(adUnitID: adUnitID, placement: placement), delegate: delegate)
            case .rewardedInterstitial:
                self.record(.rewardedInterstitial(adUnitID: adUnitID, placement: placement), delegate: delegate)
            }
            if let loadError = self.loadError { throw loadError }
            return self.rewardedAd
        }
    }

    private func record(_ request: Request, delegate: GoogleMobileAds.FullScreenContentDelegate) {
        self.requests.append(request)
        self.lastDelegate = delegate
        self.onLoad?()
    }

}

@available(iOS 15.0, *)
@MainActor
private final class FakeInterstitialAd: InterstitialPresentableAd {

    var onPresent: (() -> Void)?

    func presentInterstitial(from viewController: UIViewController) {
        self.onPresent?()
    }

}

@available(iOS 15.0, *)
@MainActor
private final class FakeRewardedAd: RewardedPresentableAd {

    var onPresent: (() -> Void)?

    func enableRewardVerification() {}

    func present(
        from viewController: UIViewController,
        rewardVerificationStarted: (@MainActor () -> Void)?,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        self.onPresent?()
    }

}

@available(iOS 15.0, *)
private final class PresentingAdStub: NSObject, GoogleMobileAds.FullScreenPresentingAd {
    weak var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
}

#endif
