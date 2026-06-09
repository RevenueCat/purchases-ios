import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) @_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class PresentRewardVerificationTests: AdapterTestCase {

    private static let testToken = (
        customData: "{}",
        clientTransactionID: "txn_present_public_api",
        appUserID: "user_present_public_api"
    )

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
        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)

        let expectation = self.expectation(description: "verification result")
        var receivedResult: RewardVerificationResult?
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { result in
                receivedResult = result
                expectation.fulfill()
            },
            pollRewardVerification: { _ in .verified(.unsupportedReward) }
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        let result = try XCTUnwrap(receivedResult)
        XCTAssertEqual(result.verifiedReward, .unsupportedReward)
    }

    func testCreateUserDidEarnRewardHandlerWithStateDeliversFailedWhenPollFails() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)

        let expectation = self.expectation(description: "failed result")
        var receivedResult: RewardVerificationResult?
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { result in
                receivedResult = result
                expectation.fulfill()
            },
            pollRewardVerification: { _ in .failed }
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)

        let result = try XCTUnwrap(receivedResult)
        XCTAssertEqual(result, .failed)
    }

    func testCreateUserDidEarnRewardHandlerWithStateInvokesStartedBeforeResult() {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)

        let expectation = self.expectation(description: "result callback")
        var events: [String] = []
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: { events.append("started") },
            rewardVerificationCompleted: { _ in
                events.append("result")
                expectation.fulfill()
            },
            pollRewardVerification: { _ in .verified(.noReward) }
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
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeCapableAd: RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
    let responseInfo = GoogleMobileAds.ResponseInfo()
}

#endif
