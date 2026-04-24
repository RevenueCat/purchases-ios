import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class PresentRewardVerificationTests: AdapterTestCase {

    private static let testAPIKey = "appl_test_present_public_api"
    private static let testAppUserID = "user_present_public_api"

    func testPresentWithoutVerificationStateInvokesOnlyStartedWhenOutcomeNil() {
        let fakeAd = FakeCapableAd()
        var startedCount = 0
        let performPresent = PerformPresentSpy()

        RewardVerification.Present.present(
            capableAd: fakeAd,
            rewardVerificationStarted: { startedCount += 1 },
            rewardVerificationOutcome: nil,
            performPresent: performPresent.callable
        )

        XCTAssertEqual(performPresent.callCount, 1)
        performPresent.invokeCapturedHandler()
        XCTAssertEqual(startedCount, 1)
    }

    func testPresentWithStateAndOutcomeDeliversVerifiedOutcome() {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let reward = VirtualCurrencyReward(code: "coins", amount: 4)
        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.verified(.virtualCurrency(reward))]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        let expectation = self.expectation(description: "public outcome")
        var receivedOutcome: RewardVerificationOutcome?
        let performPresent = PerformPresentSpy()

        RewardVerification.Present.present(
            capableAd: fakeAd,
            rewardVerificationStarted: nil,
            rewardVerificationOutcome: { outcome in
                receivedOutcome = outcome
                expectation.fulfill()
            },
            poller: poller,
            performPresent: performPresent.callable
        )

        performPresent.invokeCapturedHandler()
        self.wait(for: [expectation], timeout: 2.0)

        let outcome = try XCTUnwrap(receivedOutcome)
        XCTAssertTrue(outcome.isVerified)
        XCTAssertEqual(outcome.verifiedReward?.virtualCurrencyCode, "coins")
        XCTAssertEqual(outcome.verifiedReward?.virtualCurrencyAmount, 4)
    }

    func testPresentWithStateAndOutcomeDeliversFailedWhenPollerFails() {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.failed]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        let expectation = self.expectation(description: "failed outcome")
        var receivedOutcome: RewardVerificationOutcome?
        let performPresent = PerformPresentSpy()

        RewardVerification.Present.present(
            capableAd: fakeAd,
            rewardVerificationStarted: nil,
            rewardVerificationOutcome: { outcome in
                receivedOutcome = outcome
                expectation.fulfill()
            },
            poller: poller,
            performPresent: performPresent.callable
        )

        performPresent.invokeCapturedHandler()
        self.wait(for: [expectation], timeout: 2.0)

        let outcome = try XCTUnwrap(receivedOutcome)
        XCTAssertTrue(outcome.isFailed)
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeCapableAd: RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
}

@available(iOS 15.0, *)
private final class PerformPresentSpy {

    private(set) var callCount = 0
    private var captured: (() -> Void)?

    @MainActor
    func callable(_ handler: @escaping () -> Void) {
        self.callCount += 1
        self.captured = handler
    }

    @MainActor
    func invokeCapturedHandler() {
        self.captured?()
    }
}

#endif
