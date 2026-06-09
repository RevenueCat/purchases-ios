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

    func testInstallNoOpsWhenPurchasesIsNotConfigured() {
        // The unit-test target never calls `Purchases.configure(...)`, so this assertion
        // documents the invariant the test depends on. If a future test configures Purchases
        // globally this XCTSkip will surface the breakage instead of silently passing.
        try? XCTSkipUnless(!Purchases.isConfigured,
                           "This test depends on Purchases not being configured")
        let fakeAd = FakeRewardedAd()

        RewardVerification.Setup.install(on: fakeAd)

        XCTAssertNil(fakeAd.serverSideVerificationOptions,
                     "install(on:) must not wire SSV options when Purchases.isConfigured is false")
        XCTAssertNil(RewardVerification.stateStore.retrieve(for: fakeAd),
                     "install(on:) must not stash per-ad state when Purchases.isConfigured is false")
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

#endif
