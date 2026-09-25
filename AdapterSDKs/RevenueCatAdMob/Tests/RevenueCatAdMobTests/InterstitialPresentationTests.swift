import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
import RevenueCat
@testable import RevenueCatAdMob
@_spi(CheckpointsInternal) import RevenueCatUI

@available(iOS 15.0, *)
@MainActor
final class InterstitialPresentationTests: AdapterTestCase {

    private static let adUnitID = "ca-app-pub-test/interstitial"

    func testDismissalCompletesWithShown() throws {
        let fakeAd = FakeInterstitialAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        presentation.adDidDismissFullScreenContent(PresentingAdStub())

        XCTAssertEqual(recorder.outcomes.count, 1)
        XCTAssertTrue(try XCTUnwrap(recorder.outcomes.first).isShown)
    }

    func testPresentationFailureCompletesWithFailed() throws {
        let fakeAd = FakeInterstitialAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        presentation.ad(
            PresentingAdStub(),
            didFailToPresentFullScreenContentWithError: NSError(domain: "gma", code: 7)
        )

        let error = try XCTUnwrap(recorder.outcomes.first?.error)
        XCTAssertEqual(error.domain, "gma")
        XCTAssertEqual(error.code, 7)
    }

    func testLoadFailureCompletesWithFailedWithoutPresenting() throws {
        let presentation = self.makePresentation(
            loadResult: .failure(NSError(domain: "gma", code: 1))
        )
        let recorder = OutcomeRecorder()
        let completed = self.expectation(description: "completed")

        self.start(presentation) { outcome in
            recorder.record(outcome)
            completed.fulfill()
        }
        self.wait(for: [completed], timeout: 2.0)

        let error = try XCTUnwrap(recorder.outcomes.first?.error)
        XCTAssertEqual(error.domain, "gma")
        XCTAssertEqual(error.code, 1)
    }

    func testMissingPresentationContextCompletesWithFailedWithoutPresenting() throws {
        let fakeAd = FakeInterstitialAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd), hasPresentationContext: false)
        let recorder = OutcomeRecorder()
        let completed = self.expectation(description: "completed")

        self.start(presentation) { outcome in
            recorder.record(outcome)
            completed.fulfill()
        }
        self.wait(for: [completed], timeout: 2.0)

        let error = try XCTUnwrap(recorder.outcomes.first?.error)
        XCTAssertEqual(error.domain, InterstitialPresentationError.errorDomain)
        XCTAssertEqual(error.code, InterstitialPresentationError.noPresentationContext.errorCode)
        XCTAssertEqual(fakeAd.presentCount, 0)
    }

    func testUnsupportedMediatorCompletesWithFailedWithoutLoading() throws {
        var loadCount = 0
        let presentation = InterstitialPresentation(
            loadAd: { _, _, _ in
                loadCount += 1
                return FakeInterstitialAd()
            },
            presentingViewControllerProvider: { UIViewController() }
        )
        let recorder = OutcomeRecorder()

        presentation.start(
            adUnitID: Self.adUnitID,
            mediator: .appLovin,
            placement: "checkpoint",
            completion: recorder.record
        )

        let error = try XCTUnwrap(recorder.outcomes.first?.error)
        XCTAssertEqual(error.domain, InterstitialPresentationError.errorDomain)
        XCTAssertEqual(
            error.code,
            InterstitialPresentationError.unsupportedMediator(MediatorName.appLovin.rawValue).errorCode
        )
        XCTAssertEqual(loadCount, 0)
    }

    func testPassesAdUnitPlacementAndItselfAsDelegateToLoad() {
        let fakeAd = FakeInterstitialAd()
        var receivedAdUnitID: String?
        var receivedPlacement: String?
        weak var receivedDelegate: GoogleMobileAds.FullScreenContentDelegate?
        let presentation = InterstitialPresentation(
            loadAd: { adUnitID, placement, delegate in
                receivedAdUnitID = adUnitID
                receivedPlacement = placement
                receivedDelegate = delegate
                return fakeAd
            },
            presentingViewControllerProvider: { UIViewController() }
        )

        self.start(presentation, placement: "onboarding_done") { _ in }
        self.waitForPresentation(of: fakeAd)

        XCTAssertEqual(receivedAdUnitID, Self.adUnitID)
        XCTAssertEqual(receivedPlacement, "onboarding_done")
        XCTAssertTrue(receivedDelegate === presentation)
    }

    func testCompletesOnlyOnce() {
        let fakeAd = FakeInterstitialAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        presentation.adDidDismissFullScreenContent(PresentingAdStub())
        presentation.ad(PresentingAdStub(), didFailToPresentFullScreenContentWithError: NSError(domain: "gma", code: 7))
        presentation.adDidDismissFullScreenContent(PresentingAdStub())

        XCTAssertEqual(recorder.outcomes.count, 1)
    }

    func testOutcomeMapsToAdPresentationResult() {
        XCTAssertEqual(InterstitialPresentation.Outcome.shown.presentationResult, AdPresentationResult.shown)
        XCTAssertNotEqual(
            InterstitialPresentation.Outcome.failed(NSError(domain: "gma", code: 1)).presentationResult,
            AdPresentationResult.shown
        )
    }

    // MARK: - Helpers

    private func makePresentation(
        loadResult: Result<FakeInterstitialAd, Error>,
        hasPresentationContext: Bool = true
    ) -> InterstitialPresentation {
        let viewController = hasPresentationContext ? UIViewController() : nil
        return InterstitialPresentation(
            loadAd: { _, _, _ in try loadResult.get() },
            presentingViewControllerProvider: { viewController }
        )
    }

    private func start(
        _ presentation: InterstitialPresentation,
        placement: String = "checkpoint",
        completion: @escaping @MainActor (InterstitialPresentation.Outcome) -> Void
    ) {
        presentation.start(
            adUnitID: Self.adUnitID,
            mediator: .adMob,
            placement: placement,
            completion: completion
        )
    }

    private func waitForPresentation(of fakeAd: FakeInterstitialAd) {
        let presented = self.expectation(description: "presented")
        fakeAd.onPresent = { presented.fulfill() }
        self.wait(for: [presented], timeout: 2.0)
        XCTAssertEqual(fakeAd.presentCount, 1)
    }

}

// MARK: - Test doubles

@available(iOS 15.0, *)
@MainActor
private final class FakeInterstitialAd: InterstitialPresentableAd {

    private(set) var presentCount = 0
    var onPresent: (() -> Void)?

    func presentInterstitial(from viewController: UIViewController) {
        self.presentCount += 1
        self.onPresent?()
    }

}

@available(iOS 15.0, *)
@MainActor
private final class OutcomeRecorder {

    private(set) var outcomes: [InterstitialPresentation.Outcome] = []

    func record(_ outcome: InterstitialPresentation.Outcome) {
        self.outcomes.append(outcome)
    }

}

@available(iOS 15.0, *)
private extension InterstitialPresentation.Outcome {

    var isShown: Bool {
        if case .shown = self { return true }
        return false
    }

    var error: NSError? {
        if case let .failed(error) = self { return error }
        return nil
    }

}

@available(iOS 15.0, *)
private final class PresentingAdStub: NSObject, GoogleMobileAds.FullScreenPresentingAd {
    weak var fullScreenContentDelegate: GoogleMobileAds.FullScreenContentDelegate?
}

#endif
