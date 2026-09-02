import Nimble
import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) @_spi(Experimental) import RevenueCat
@_spi(Experimental) @testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class PresentRewardVerificationTests: AdapterTestCase {

    private static let testToken = RewardVerificationToken(
        customData: "{}",
        clientTransactionID: "txn_present_public_api",
        appUserID: "user_present_public_api"
    )

    func testCreateUserDidEarnRewardHandlerWithoutVerificationStateInvokesOnlyStartedWhenCompletedHandlerNil() {
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
            pollRewardVerification: { _, _ in .verified(.unsupportedReward) }
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
            pollRewardVerification: { _, _ in .failed }
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
            pollRewardVerification: { _, _ in .verified(.noReward) }
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(events, ["started", "result"])
    }

    func testCreateUserDidEarnRewardHandlerPassesNoTrackingMetadataWhenAdWasNotTracked() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)

        let metadata = try self.pollTrackingMetadata(for: fakeAd)
        XCTAssertNil(metadata)
    }

    func testCreateUserDidEarnRewardHandlerPassesTrackingMetadataFromTheTrackingDelegate() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)
        self.installTrackingDelegate(on: fakeAd, placement: "load_time_placement")

        let metadata = try XCTUnwrap(self.pollTrackingMetadata(for: fakeAd))
        XCTAssertEqual(metadata.mediatorName, .adMob)
        XCTAssertEqual(metadata.adFormat, .rewarded)
        XCTAssertEqual(metadata.placement, "load_time_placement")
        XCTAssertEqual(metadata.adUnitId, "ad_unit_id")
        XCTAssertEqual(metadata.impressionId, "response_id")
        XCTAssertEqual(metadata.networkName, "")
    }

    func testCreateUserDidEarnRewardHandlerPassesTrackingMetadataWithTheShowTimePlacement() throws {
        let fakeAd = FakeCapableAd()
        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)
        self.installTrackingDelegate(on: fakeAd, placement: "load_time_placement")

        Tracking.setShowTimePlacement("show_time_placement", on: fakeAd)

        let metadata = try XCTUnwrap(self.pollTrackingMetadata(for: fakeAd))
        XCTAssertEqual(metadata.placement, "show_time_placement")
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

    // MARK: - Helpers

    private func installTrackingDelegate(on fakeAd: FakeCapableAd, placement: String?) {
        let trackingDelegate = Tracking.FullScreenContentDelegate(
            delegate: nil,
            placement: placement,
            adUnitID: "ad_unit_id",
            adFormat: .rewarded,
            responseInfoProvider: { fakeAd.responseInfo }
        )
        Tracking.Adapter.shared.fullScreenDelegateStore.set(trackingDelegate, for: fakeAd)
    }

    /// Runs the reward handler and returns the tracking metadata the adapter handed to the poll call.
    private func pollTrackingMetadata(for fakeAd: FakeCapableAd) throws -> RewardedAdTrackingMetadata? {
        let expectation = self.expectation(description: "poll called")
        let received = Box<RewardedAdTrackingMetadata?>(nil)
        let handler = fakeAd.createUserDidEarnRewardHandler(
            rewardVerificationStarted: nil,
            rewardVerificationCompleted: { _ in },
            pollRewardVerification: { _, trackingMetadata in
                received.value = trackingMetadata
                expectation.fulfill()
                return .verified(.noReward)
            }
        )

        handler()
        self.wait(for: [expectation], timeout: 2.0)
        return received.value
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeCapableAd: RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
    let responseInfo: GoogleMobileAds.ResponseInfo = unsafeBitCast(
        FakeResponseInfo(),
        to: GoogleMobileAds.ResponseInfo.self
    )
}

@available(iOS 15.0, *)
private final class FakeResponseInfo: NSObject {
    @objc var responseIdentifier: String? { "response_id" }
    @objc var loadedAdNetworkResponseInfo: AnyObject? { nil }
}

/// Minimal box so the poll closure can hand its argument back to the test body.
private final class Box<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        self.storage = value
    }

    var value: Value {
        get { self.lock.withLock { self.storage } }
        set { self.lock.withLock { self.storage = newValue } }
    }
}

#endif
