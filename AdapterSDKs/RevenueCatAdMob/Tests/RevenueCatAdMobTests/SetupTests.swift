import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class SetupTests: AdapterTestCase {

    private static let testToken = (
        customData: "{\"api_key\":\"appl_test_api_key\",\"client_transaction_id\":\"txn_42\",\"impression_id\":\"imp\"}",
        clientTransactionID: "txn_42",
        appUserID: "user_test_42"
    )

    // MARK: - install(on:token:)

    func testInstallReturnsStateWithTokenClientTransactionID() {
        let fakeAd = FakeRewardedAd()

        let state = RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)

        XCTAssertEqual(state.clientTransactionID, Self.testToken.clientTransactionID)
    }

    func testInstallSetsServerSideVerificationOptionsWithUserIdentifier() throws {
        let fakeAd = FakeRewardedAd()

        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)

        let options = try XCTUnwrap(fakeAd.serverSideVerificationOptions)
        XCTAssertEqual(options.userIdentifier, Self.testToken.appUserID)
    }

    func testInstallSetsCustomRewardTextFromTokenCustomData() throws {
        let fakeAd = FakeRewardedAd()

        RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)

        let customRewardText = try XCTUnwrap(fakeAd.serverSideVerificationOptions?.customRewardText)
        XCTAssertEqual(customRewardText, Self.testToken.customData)
    }

    func testInstallStashesStateRetrievableViaStateStore() throws {
        let fakeAd = FakeRewardedAd()

        let returnedState = RewardVerification.Setup.install(on: fakeAd, token: Self.testToken)
        let stashedState = try XCTUnwrap(RewardVerification.stateStore.retrieve(for: fakeAd))

        XCTAssertTrue(returnedState === stashedState,
                      "RewardVerification.stateStore.retrieve(for:) must return the exact instance produced by install")
    }

    // MARK: - install(on:)

    func testInstallWhenConfiguredWiresTokenAndStashesState() throws {
        let fakeAd = FakeRewardedAd()
        let provider = MockTokenProvider(isConfigured: true, token: Self.testToken)

        RewardVerification.Setup.install(on: fakeAd, tokenProvider: provider)

        let options = try XCTUnwrap(fakeAd.serverSideVerificationOptions)
        XCTAssertEqual(options.customRewardText, Self.testToken.customData)
        XCTAssertEqual(options.userIdentifier, Self.testToken.appUserID)

        let state = try XCTUnwrap(RewardVerification.stateStore.retrieve(for: fakeAd))
        XCTAssertEqual(state.clientTransactionID, Self.testToken.clientTransactionID)
    }

    func testInstallForwardsAdImpressionIdToTokenProvider() {
        let fakeAd = FakeRewardedAd()
        let provider = MockTokenProvider(isConfigured: true, token: Self.testToken)

        RewardVerification.Setup.install(on: fakeAd, tokenProvider: provider)

        XCTAssertEqual(provider.receivedImpressionIds,
                       [Tracking.Adapter.impressionID(from: fakeAd.responseInfo)])
    }

    func testInstallNoOpsWhenTokenProviderNotConfigured() {
        let fakeAd = FakeRewardedAd()
        let provider = MockTokenProvider(isConfigured: false, token: Self.testToken)

        RewardVerification.Setup.install(on: fakeAd, tokenProvider: provider)

        XCTAssertNil(fakeAd.serverSideVerificationOptions,
                     "install(on:) must not wire SSV options when the provider is not configured")
        XCTAssertNil(RewardVerification.stateStore.retrieve(for: fakeAd),
                     "install(on:) must not stash per-ad state when the provider is not configured")
        XCTAssertTrue(provider.receivedImpressionIds.isEmpty,
                      "install(on:) must not request a token when not configured")
    }

    func testInstallOverwritesPreviouslyStashedStateOnSameAd() throws {
        let fakeAd = FakeRewardedAd()

        let firstToken = (customData: "{}", clientTransactionID: "txn_first", appUserID: "user")
        let secondToken = (customData: "{}", clientTransactionID: "txn_second", appUserID: "user")

        let firstState = RewardVerification.Setup.install(on: fakeAd, token: firstToken)
        let secondState = RewardVerification.Setup.install(on: fakeAd, token: secondToken)
        let stashedState = try XCTUnwrap(RewardVerification.stateStore.retrieve(for: fakeAd))

        XCTAssertFalse(firstState === secondState)
        XCTAssertTrue(stashedState === secondState)
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeRewardedAd: RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
    let responseInfo = GoogleMobileAds.ResponseInfo()
}

@available(iOS 15.0, *)
private final class MockTokenProvider: RewardVerification.TokenProvider {

    var isConfigured: Bool
    let token: (customData: String, clientTransactionID: String, appUserID: String)
    private(set) var receivedImpressionIds: [String] = []

    init(isConfigured: Bool, token: (customData: String, clientTransactionID: String, appUserID: String)) {
        self.isConfigured = isConfigured
        self.token = token
    }

    func generateToken(
        impressionId: String
    ) -> (customData: String, clientTransactionID: String, appUserID: String) {
        self.receivedImpressionIds.append(impressionId)
        return self.token
    }
}

#endif
