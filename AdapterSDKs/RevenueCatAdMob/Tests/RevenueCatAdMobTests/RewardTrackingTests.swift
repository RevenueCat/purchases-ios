import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Experimental) @_spi(Internal) @testable import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class RewardTrackingTests: AdapterTestCase {

    private static let testAPIKey = "appl_test_reward_tracking"
    private static let testAppUserID = "user_reward_tracking"

    private var mockTracker: MockAdTracker!
    private var fakeAd: FakeRewardedAd!

    override func setUp() {
        super.setUp()
        self.mockTracker = MockAdTracker()
        self.fakeAd = FakeRewardedAd()
    }

    // MARK: - AdRewardEarnedUnverified

    func testHandlerFiresRewardEarnedUnverifiedWithStateMetadata() {
        RewardVerification.Setup.install(on: self.fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let handler = self.fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: nil,
            tracker: self.mockTracker
        )
        handler()

        XCTAssertEqual(self.mockTracker.rewardEarnedUnverifiedData.count, 1)
        let event = self.mockTracker.rewardEarnedUnverifiedData[0]
        expect(event.mediatorName) == .adMob
        expect(event.adFormat) == .rewarded
        expect(event.adUnitId) == self.fakeAd.adUnitID
        expect(event.rewardVerificationEnabled) == true
        expect(event.impressionId) == ""
    }

    func testHandlerFiresRewardEarnedUnverifiedEvenWithoutVerificationState() {
        let handler = self.fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: nil,
            tracker: self.mockTracker
        )
        handler()

        XCTAssertEqual(self.mockTracker.rewardEarnedUnverifiedData.count, 1)
        let event = self.mockTracker.rewardEarnedUnverifiedData[0]
        expect(event.rewardVerificationEnabled) == false
        expect(event.impressionId) == ""
    }

    func testFireEarnedUnverifiedEventDirectlyEmitsExpectedFields() {
        self.fakeAd.fireEarnedUnverifiedEvent(
            tracker: self.mockTracker,
            impressionId: "imp-loadAndTrack",
            rewardVerificationEnabled: false
        )

        XCTAssertEqual(self.mockTracker.rewardEarnedUnverifiedData.count, 1)
        let event = self.mockTracker.rewardEarnedUnverifiedData[0]
        expect(event.mediatorName) == .adMob
        expect(event.adFormat) == .rewarded
        expect(event.adUnitId) == self.fakeAd.adUnitID
        expect(event.impressionId) == "imp-loadAndTrack"
        expect(event.rewardVerificationEnabled) == false
    }

    // MARK: - AdRewardVerified

    func testVirtualCurrencyOutcomeFiresVerifiedWithCurrencyFields() throws {
        RewardVerification.Setup.install(on: self.fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "GOLD", amount: 50))
        let poller = self.makePoller(statuses: [.verified(.virtualCurrency(reward))])

        self.runHandler(poller: poller, expectationDescription: "verified vc outcome")

        XCTAssertEqual(self.mockTracker.rewardVerifiedData.count, 1)
        let event = self.mockTracker.rewardVerifiedData[0]
        expect(event.reward.virtualCurrency).toNot(beNil())
        expect(event.reward.virtualCurrency?.code) == "GOLD"
        expect(event.reward.virtualCurrency?.amount) == 50
        XCTAssertTrue(self.mockTracker.rewardFailedToVerifyData.isEmpty)
    }

    func testNoRewardOutcomeFiresVerifiedWithNilCurrencyFields() {
        RewardVerification.Setup.install(on: self.fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = self.makePoller(statuses: [.verified(.noReward)])
        self.runHandler(poller: poller, expectationDescription: "verified no-reward outcome")

        XCTAssertEqual(self.mockTracker.rewardVerifiedData.count, 1)
        let event = self.mockTracker.rewardVerifiedData[0]
        expect(event.reward) == .noReward
        expect(event.reward.virtualCurrency).to(beNil())
    }

    func testUnsupportedRewardOutcomeFiresVerifiedWithNilCurrencyFields() {
        RewardVerification.Setup.install(on: self.fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = self.makePoller(statuses: [.verified(.unsupportedReward)])
        self.runHandler(poller: poller, expectationDescription: "verified unsupported outcome")

        XCTAssertEqual(self.mockTracker.rewardVerifiedData.count, 1)
        let event = self.mockTracker.rewardVerifiedData[0]
        expect(event.reward) == .unsupportedReward
        expect(event.reward.virtualCurrency).to(beNil())
    }

    // MARK: - AdRewardFailedToVerify

    func testTimeoutFailureFiresFailedToVerify() {
        RewardVerification.Setup.install(on: self.fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = self.makePoller(statuses: [.pending, .pending, .pending], maxAttempts: 3)
        self.runHandler(poller: poller, expectationDescription: "timeout outcome")

        XCTAssertEqual(self.mockTracker.rewardFailedToVerifyData.count, 1)
        let event = self.mockTracker.rewardFailedToVerifyData[0]
        expect(event.failureReason) == .timeout
        XCTAssertTrue(self.mockTracker.rewardVerifiedData.isEmpty)
    }

    func testBackendFailureFiresFailedToVerify() {
        RewardVerification.Setup.install(on: self.fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let poller = self.makePoller(statuses: [.failed])
        self.runHandler(poller: poller, expectationDescription: "backend failure outcome")

        XCTAssertEqual(self.mockTracker.rewardFailedToVerifyData.count, 1)
        expect(self.mockTracker.rewardFailedToVerifyData[0].failureReason) == .backendError
    }

    func testUnknownFailureFiresFailedToVerify() {
        RewardVerification.Setup.install(on: self.fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let throwingPoller = ThrowingStatusPoller(error: SentinelError())
        let poller = RewardVerification.Poller(
            statusPoller: throwingPoller,
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: 3
        )
        self.runHandler(poller: poller, expectationDescription: "unknown failure outcome")

        XCTAssertEqual(self.mockTracker.rewardFailedToVerifyData.count, 1)
        expect(self.mockTracker.rewardFailedToVerifyData[0].failureReason) == .unknown
    }

    // MARK: - Helpers

    private func makePoller(
        statuses: [RewardVerificationPollStatus],
        maxAttempts: Int = 5
    ) -> RewardVerification.Poller {
        RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: statuses),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: maxAttempts
        )
    }

    private func runHandler(
        poller: RewardVerification.Poller,
        expectationDescription: String
    ) {
        let expectation = self.expectation(description: expectationDescription)
        let handler = self.fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { _ in expectation.fulfill() },
            poller: poller,
            tracker: self.mockTracker,
            invalidateVirtualCurrenciesCache: {}
        )
        handler()
        self.wait(for: [expectation], timeout: 2.0)
    }
}

@available(iOS 15.0, *)
private final class FakeRewardedAd: NSObject, RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
    let responseInfo: GoogleMobileAds.ResponseInfo = unsafeBitCast(
        FakeResponseInfo(),
        to: GoogleMobileAds.ResponseInfo.self
    )
    var adUnitID: String = "ca-app-pub-reward-tracking"
    var adReward: GoogleMobileAds.AdReward = .init()
    var rewardedAdFormat: RevenueCat.AdFormat = .rewarded
}

@available(iOS 15.0, *)
private final class FakeResponseInfo: NSObject {
    @objc var responseIdentifier: String? { nil }
    @objc var loadedAdNetworkResponseInfo: AnyObject? { nil }
}

#endif
