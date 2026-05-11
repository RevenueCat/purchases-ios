import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class PresentRewardVerificationTests: AdapterTestCase {

    private static let testAPIKey = "appl_test_present_public_api"
    private static let testAppUserID = "user_present_public_api"

    func testPresentWithoutVerificationStateInvokesOnlyStartedWhenOutcomeNil() {
        let fakeAd = FakeCapableAd()
        var startedCount = 0
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: { startedCount += 1 },
            rewardVerificationResult: nil
        )

        handler()
        XCTAssertEqual(startedCount, 1)
    }

    func testPresentWithStateAndOutcomeDeliversVerifiedOutcome() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let reward = VirtualCurrencyReward(code: "coins", amount: 4)
        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.verified(.virtualCurrency(reward))]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        let expectation = self.expectation(description: "verification result")
        var receivedResult: RewardVerificationResult?
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationResult: { result in
                receivedResult = result
                expectation.fulfill()
            },
            poller: poller
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        let result = try XCTUnwrap(receivedResult)
        XCTAssertNotNil(result.verifiedReward)
        XCTAssertEqual(result.verifiedReward?.virtualCurrency?.code, "coins")
        XCTAssertEqual(result.verifiedReward?.virtualCurrency?.amount, 4)
    }

    func testPresentWithStateAndOutcomeDeliversFailedWhenPollerFails() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.failed]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        let expectation = self.expectation(description: "failed result")
        var receivedResult: RewardVerificationResult?
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationResult: { result in
                receivedResult = result
                expectation.fulfill()
            },
            poller: poller
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        let result = try XCTUnwrap(receivedResult)
        XCTAssertTrue(result.isFailed)
    }

    func testPresentWithStateInvokesStartedBeforeResult() {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.verified(.noReward)]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        let expectation = self.expectation(description: "result callback")
        var events: [String] = []
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: {
                events.append("started")
            },
            rewardVerificationResult: { _ in
                events.append("result")
                expectation.fulfill()
            },
            poller: poller
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(events, ["started", "result"])
    }

    func testCreateUserDidEarnRewardHandlerAssertsWhenResultCallbackProvidedWithoutVerificationState() {
        let fakeAd = FakeCapableAd()

        expect {
            _ = fakeAd.createUserDidEarnRewardHandler(
                rewardVerificationStarted: nil,
                rewardVerificationResult: { _ in }
            )
        }.to(throwAssertion())
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeCapableAd: RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
}

#endif
