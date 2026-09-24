import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(CheckpointsInternal) @testable import RevenueCatAdMob
@_spi(CheckpointsInternal) import RevenueCatUI

@available(iOS 15.0, *)
@MainActor
final class AdMobPresenterTests: AdapterTestCase {

    private let interstitial = RecordingPresenter()
    private let rewarded = RecordingPresenter()
    private let rewardedInterstitial = RecordingPresenter()
    private lazy var presenter = AdMobPresenter(
        interstitialPresenter: self.interstitial,
        rewardedPresenter: self.rewarded,
        rewardedInterstitialPresenter: self.rewardedInterstitial
    )

    // MARK: - Dispatch by format

    func testInterstitialFormatIsDelegatedToTheInterstitialPresenter() {
        self.presenter.present(params: Self.params(adFormat: .interstitial)) { _ in }

        XCTAssertEqual(self.interstitial.params.map(\.adFormat), [.interstitial])
        XCTAssertTrue(self.rewarded.params.isEmpty)
        XCTAssertTrue(self.rewardedInterstitial.params.isEmpty)
    }

    func testRewardedFormatIsDelegatedToTheRewardedPresenter() {
        self.presenter.present(params: Self.params(adFormat: .rewarded)) { _ in }

        XCTAssertEqual(self.rewarded.params.map(\.adFormat), [.rewarded])
        XCTAssertTrue(self.interstitial.params.isEmpty)
        XCTAssertTrue(self.rewardedInterstitial.params.isEmpty)
    }

    func testRewardedInterstitialFormatIsDelegatedToTheRewardedInterstitialPresenter() {
        self.presenter.present(params: Self.params(adFormat: .rewardedInterstitial)) { _ in }

        XCTAssertEqual(self.rewardedInterstitial.params.map(\.adFormat), [.rewardedInterstitial])
        XCTAssertTrue(self.interstitial.params.isEmpty)
        XCTAssertTrue(self.rewarded.params.isEmpty)
    }

    func testForwardsTheParamsUnchanged() throws {
        self.presenter.present(
            params: Self.params(checkpointIdentifier: "level_complete", adFormat: .rewarded, mediator: .appLovin)
        ) { _ in }

        let forwarded = try XCTUnwrap(self.rewarded.params.first)
        XCTAssertEqual(forwarded.checkpointIdentifier, "level_complete")
        XCTAssertEqual(forwarded.adIdentifier, "ad-unit")
        XCTAssertEqual(forwarded.mediator, .appLovin)
    }

    func testForwardsTheSubPresenterResultToTheCompletion() throws {
        var results: [AdPresentationResult] = []

        self.presenter.present(params: Self.params(adFormat: .rewarded)) { result in
            results.append(result)
        }
        XCTAssertTrue(results.isEmpty)

        try XCTUnwrap(self.rewarded.completions.first)(.rewardVerificationFailed)

        XCTAssertEqual(results, [.rewardVerificationFailed])
    }

    // MARK: - Unsupported formats

    func testUnsupportedFormatFailsImmediatelyWithoutDelegating() {
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
        XCTAssertTrue(self.interstitial.params.isEmpty)
        XCTAssertTrue(self.rewarded.params.isEmpty)
        XCTAssertTrue(self.rewardedInterstitial.params.isEmpty)
    }

    func testUnsupportedFormatErrorDescribesTheFormatAndTheSupportedOnes() {
        let error = AdMobPresentationError.unsupportedFormat("banner") as NSError

        XCTAssertEqual(error.domain, "RevenueCatAdMob.AdMobPresentationError")
        XCTAssertEqual(error.code, 1)
        XCTAssertTrue(error.localizedDescription.contains("'banner'"))
        XCTAssertTrue(error.localizedDescription.contains("rewarded_interstitial"))
    }

    // MARK: - Helpers

    private static func params(
        checkpointIdentifier: String = "checkpoint_id",
        adFormat: RevenueCat.AdFormat,
        mediator: MediatorName = .adMob
    ) -> AdPresentationParams {
        return AdPresentationParams(
            checkpointIdentifier: checkpointIdentifier,
            adIdentifier: "ad-unit",
            mediator: mediator,
            adFormat: adFormat
        )
    }

}

// MARK: - Test doubles

@available(iOS 15.0, *)
@MainActor
private final class RecordingPresenter: AdPresenter {

    private(set) var params: [AdPresentationParams] = []
    private(set) var completions: [AdPresentationCompletion] = []

    func present(params: AdPresentationParams, completion: @escaping AdPresentationCompletion) {
        self.params.append(params)
        self.completions.append(completion)
    }

}

#endif
