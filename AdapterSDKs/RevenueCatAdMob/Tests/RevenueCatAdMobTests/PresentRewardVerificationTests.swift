import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) @_spi(Experimental) @testable import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class PresentRewardVerificationTests: AdapterTestCase {

    private static let testAPIKey = "appl_test_present_public_api"
    private static let testAppUserID = "user_present_public_api"

    func testCreateUserDidEarnRewardHandlerWithoutVerificationStateInvokesOnlyStartedWhenOutcomeNil() {
        let fakeAd = FakeCapableAd()
        var startedCount = 0
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: { startedCount += 1 },
            rewardVerificationCompleted: nil
        )

        handler()
        XCTAssertEqual(startedCount, 1)
    }
    func testCreateUserDidEarnRewardHandlerWithStateDeliversVerifiedOutcome() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 4))
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
            rewardVerificationCompleted: { result in
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

    func testCreateUserDidEarnRewardHandlerWithStateDeliversFailedWhenPollerFails() throws {
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
            rewardVerificationCompleted: { result in
                receivedResult = result
                expectation.fulfill()
            },
            poller: poller
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        let result = try XCTUnwrap(receivedResult)
        XCTAssertEqual(result, .failed)
    }

    func testCreateUserDidEarnRewardHandlerWithStateInvokesStartedBeforeResult() {
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
            rewardVerificationCompleted: { _ in
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
                rewardVerificationCompleted: { _ in }
            )
        }.to(throwAssertion())
    }

    func testCreateUserDidEarnRewardHandlerWithVerifiedVirtualCurrencyInvalidatesVirtualCurrenciesCache() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 4))
        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.verified(.virtualCurrency(reward))]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        var invalidationCallCount = 0
        let invalidateVirtualCurrenciesCache = {
            invalidationCallCount += 1
        }

        let expectation = self.expectation(description: "verification callback")
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { _ in
                expectation.fulfill()
            },
            poller: poller,
            invalidateVirtualCurrenciesCache: invalidateVirtualCurrenciesCache
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(invalidationCallCount, 1)
    }

    func testCreateUserDidEarnRewardHandlerWithNoRewardDoesNotInvalidateVirtualCurrenciesCache() {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.verified(.noReward)]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        var invalidationCallCount = 0
        let invalidateVirtualCurrenciesCache = {
            invalidationCallCount += 1
        }

        let expectation = self.expectation(description: "verification callback")
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { _ in
                expectation.fulfill()
            },
            poller: poller,
            invalidateVirtualCurrenciesCache: invalidateVirtualCurrenciesCache
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(invalidationCallCount, 0)
    }

    func testCreateUserDidEarnRewardHandlerWithUnsupportedRewardDoesNotInvalidateVirtualCurrenciesCache() {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.verified(.unsupportedReward)]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        var invalidationCallCount = 0
        let invalidateVirtualCurrenciesCache = {
            invalidationCallCount += 1
        }

        let expectation = self.expectation(description: "verification callback")
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { _ in
                expectation.fulfill()
            },
            poller: poller,
            invalidateVirtualCurrenciesCache: invalidateVirtualCurrenciesCache
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(invalidationCallCount, 0)
    }

    func testCreateUserDidEarnRewardHandlerWithFailedOutcomeDoesNotInvalidateVirtualCurrenciesCache() {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: [.failed]),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 5
        )

        var invalidationCallCount = 0
        let invalidateVirtualCurrenciesCache = {
            invalidationCallCount += 1
        }

        let expectation = self.expectation(description: "verification callback")
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { _ in
                expectation.fulfill()
            },
            poller: poller,
            invalidateVirtualCurrenciesCache: invalidateVirtualCurrenciesCache
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(invalidationCallCount, 0)
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeCapableAd: RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
    let responseInfo = GoogleMobileAds.ResponseInfo()
}

#endif
