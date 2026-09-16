import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob
@_spi(CheckpointsInternal) import RevenueCatUI

@available(iOS 15.0, *)
@MainActor
final class RewardedPresentationTests: AdapterTestCase {

    private static let adUnitID = "ca-app-pub-test/rewarded"

    func testDismissalWithoutEarningRewardCompletesWithShown() throws {
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        presentation.adDidDismissFullScreenContent(PresentingAdStub())

        XCTAssertEqual(recorder.outcomes.count, 1)
        XCTAssertTrue(try XCTUnwrap(recorder.outcomes.first).isShown)
    }

    func testEnablesRewardVerificationBeforePresenting() {
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))

        self.start(presentation) { _ in }
        self.waitForPresentation(of: fakeAd)

        XCTAssertEqual(fakeAd.events, [.enableRewardVerification, .present])
    }

    func testVerifiedRewardAfterDismissalCompletesWithRewarded() throws {
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        fakeAd.earnReward()
        presentation.adDidDismissFullScreenContent(PresentingAdStub())
        XCTAssertTrue(recorder.outcomes.isEmpty, "Must wait for verification before completing")

        fakeAd.completeVerification(.verified(.unsupportedReward, moreRewards: [.noReward]))

        XCTAssertEqual(recorder.outcomes.count, 1)
        let rewarded = try XCTUnwrap(recorder.outcomes.first?.rewarded)
        XCTAssertEqual(rewarded.reward, .unsupportedReward)
        XCTAssertEqual(rewarded.moreRewards, [.noReward])
    }

    func testVerifiedRewardBeforeDismissalWaitsForDismissal() throws {
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        fakeAd.earnReward()
        fakeAd.completeVerification(.verified(.unsupportedReward))
        XCTAssertTrue(recorder.outcomes.isEmpty, "Must not complete while the ad is still on screen")

        presentation.adDidDismissFullScreenContent(PresentingAdStub())

        XCTAssertEqual(recorder.outcomes.count, 1)
        XCTAssertEqual(try XCTUnwrap(recorder.outcomes.first?.rewarded).reward, .unsupportedReward)
    }

    func testVerifiedNoRewardCompletesWithRewardedCarryingNoReward() throws {
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        fakeAd.earnReward()
        presentation.adDidDismissFullScreenContent(PresentingAdStub())
        fakeAd.completeVerification(.verified(.noReward))

        let rewarded = try XCTUnwrap(recorder.outcomes.first?.rewarded)
        XCTAssertEqual(rewarded.reward, .noReward)
        XCTAssertTrue(rewarded.moreRewards.isEmpty)
    }

    func testFailedVerificationCompletesWithRewardVerificationFailed() throws {
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        fakeAd.earnReward()
        presentation.adDidDismissFullScreenContent(PresentingAdStub())
        fakeAd.completeVerification(.failed)

        XCTAssertEqual(recorder.outcomes.count, 1)
        XCTAssertTrue(try XCTUnwrap(recorder.outcomes.first).isRewardVerificationFailed)
    }

    func testPresentationFailureCompletesWithFailed() throws {
        let fakeAd = FakeRewardedAd()
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
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd), hasPresentationContext: false)
        let recorder = OutcomeRecorder()
        let completed = self.expectation(description: "completed")

        self.start(presentation) { outcome in
            recorder.record(outcome)
            completed.fulfill()
        }
        self.wait(for: [completed], timeout: 2.0)

        let error = try XCTUnwrap(recorder.outcomes.first?.error)
        XCTAssertEqual(error.domain, RewardedPresentationError.errorDomain)
        XCTAssertEqual(error.code, RewardedPresentationError.noPresentationContext.errorCode)
        XCTAssertTrue(fakeAd.events.isEmpty)
    }

    func testUnsupportedMediatorCompletesWithFailedWithoutLoading() throws {
        var loadCount = 0
        let presentation = RewardedPresentation(
            loadAd: { _, _, _ in
                loadCount += 1
                return FakeRewardedAd()
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
        XCTAssertEqual(error.domain, RewardedPresentationError.errorDomain)
        XCTAssertEqual(
            error.code,
            RewardedPresentationError.unsupportedMediator(MediatorName.appLovin.rawValue).errorCode
        )
        XCTAssertEqual(loadCount, 0)
    }

    func testPassesAdUnitPlacementAndItselfAsDelegateToLoad() {
        let fakeAd = FakeRewardedAd()
        var receivedAdUnitID: String?
        var receivedPlacement: String?
        weak var receivedDelegate: GoogleMobileAds.FullScreenContentDelegate?
        let presentation = RewardedPresentation(
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
        let fakeAd = FakeRewardedAd()
        let presentation = self.makePresentation(loadResult: .success(fakeAd))
        let recorder = OutcomeRecorder()

        self.start(presentation, completion: recorder.record)
        self.waitForPresentation(of: fakeAd)

        fakeAd.earnReward()
        presentation.adDidDismissFullScreenContent(PresentingAdStub())
        fakeAd.completeVerification(.verified(.noReward))
        fakeAd.completeVerification(.failed)
        presentation.ad(PresentingAdStub(), didFailToPresentFullScreenContentWithError: NSError(domain: "gma", code: 7))
        presentation.adDidDismissFullScreenContent(PresentingAdStub())

        XCTAssertEqual(recorder.outcomes.count, 1)
    }

    func testOutcomeMapsToAdPresentationResult() {
        XCTAssertTrue(RewardedPresentation.Outcome.shown.presentationResult === AdPresentationResult.shown)
        XCTAssertTrue(
            RewardedPresentation.Outcome.rewardVerificationFailed.presentationResult
                === AdPresentationResult.rewardVerificationFailed
        )

        let rewarded = RewardedPresentation.Outcome.rewarded(.noReward, moreRewards: []).presentationResult
        XCTAssertFalse(rewarded === AdPresentationResult.shown)
        XCTAssertFalse(rewarded === AdPresentationResult.rewardVerificationFailed)

        let failed = RewardedPresentation.Outcome.failed(NSError(domain: "gma", code: 1)).presentationResult
        XCTAssertFalse(failed === AdPresentationResult.shown)
        XCTAssertFalse(failed === AdPresentationResult.rewardVerificationFailed)
    }

    // MARK: - Helpers

    private func makePresentation(
        loadResult: Result<FakeRewardedAd, Error>,
        hasPresentationContext: Bool = true
    ) -> RewardedPresentation {
        let viewController = hasPresentationContext ? UIViewController() : nil
        return RewardedPresentation(
            loadAd: { _, _, _ in try loadResult.get() },
            presentingViewControllerProvider: { viewController }
        )
    }

    private func start(
        _ presentation: RewardedPresentation,
        placement: String = "checkpoint",
        completion: @escaping @MainActor (RewardedPresentation.Outcome) -> Void
    ) {
        presentation.start(
            adUnitID: Self.adUnitID,
            mediator: .adMob,
            placement: placement,
            completion: completion
        )
    }

    private func waitForPresentation(of fakeAd: FakeRewardedAd) {
        let presented = self.expectation(description: "presented")
        fakeAd.onPresent = { presented.fulfill() }
        self.wait(for: [presented], timeout: 2.0)
        XCTAssertEqual(fakeAd.events.filter { $0 == .present }.count, 1)
    }

}

// MARK: - Test doubles

@available(iOS 15.0, *)
@MainActor
private final class FakeRewardedAd: RewardedPresentableAd {

    enum Event: Equatable {
        case enableRewardVerification
        case present
    }

    private(set) var events: [Event] = []
    var onPresent: (() -> Void)?

    private var rewardVerificationStarted: (@MainActor () -> Void)?
    private var rewardVerificationCompleted: (@MainActor (RewardVerificationResult) -> Void)?

    func enableRewardVerification() {
        self.events.append(.enableRewardVerification)
    }

    func presentRewarded(
        from viewController: UIViewController,
        rewardVerificationStarted: @escaping @MainActor () -> Void,
        rewardVerificationCompleted: @escaping @MainActor (RewardVerificationResult) -> Void
    ) {
        self.events.append(.present)
        self.rewardVerificationStarted = rewardVerificationStarted
        self.rewardVerificationCompleted = rewardVerificationCompleted
        self.onPresent?()
    }

    /// Simulates AdMob's `userDidEarnRewardHandler` firing, which starts verification.
    func earnReward() {
        self.rewardVerificationStarted?()
    }

    func completeVerification(_ result: RewardVerificationResult) {
        self.rewardVerificationCompleted?(result)
    }

}

@available(iOS 15.0, *)
@MainActor
private final class OutcomeRecorder {

    private(set) var outcomes: [RewardedPresentation.Outcome] = []

    func record(_ outcome: RewardedPresentation.Outcome) {
        self.outcomes.append(outcome)
    }

}

@available(iOS 15.0, *)
private extension RewardedPresentation.Outcome {

    var isShown: Bool {
        if case .shown = self { return true }
        return false
    }

    var isRewardVerificationFailed: Bool {
        if case .rewardVerificationFailed = self { return true }
        return false
    }

    var rewarded: (reward: RevenueCat.AdReward, moreRewards: [RevenueCat.AdReward])? {
        if case let .rewarded(reward, moreRewards) = self { return (reward, moreRewards) }
        return nil
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
