import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
@MainActor
final class SetupTests: AdapterTestCase {

    private static let testAPIKey = "appl_test_api_key"
    private static let testAppUserID = "user_test_42"

    // MARK: - install(on:apiKey:appUserID:)

    func testInstallReturnsStateWithGeneratedClientTransactionID() {
        let fakeAd = FakeRewardedAd()

        let state = RewardVerification.Setup.install(
            on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID
        )

        let unwrapped = try? XCTUnwrap(state)
        XCTAssertNotNil(unwrapped?.clientTransactionID)
        XCTAssertNotNil(UUID(uuidString: unwrapped?.clientTransactionID ?? ""),
                        "client_transaction_id must be a valid UUID string")
    }

    func testInstallSetsServerSideVerificationOptionsWithUserIdentifier() throws {
        let fakeAd = FakeRewardedAd()

        RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)

        let options = try XCTUnwrap(fakeAd.serverSideVerificationOptions)
        XCTAssertEqual(options.userIdentifier, Self.testAppUserID)
    }

    func testInstallSetsCustomRewardTextWithApiKeyAndClientTransactionID() throws {
        let fakeAd = FakeRewardedAd()

        let state = try XCTUnwrap(
            RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)
        )
        let customRewardText = try XCTUnwrap(fakeAd.serverSideVerificationOptions?.customRewardText)
        let payload = try Self.parseJSONObject(customRewardText)

        XCTAssertEqual(payload["api_key"], Self.testAPIKey)
        XCTAssertEqual(payload["client_transaction_id"], state.clientTransactionID)
    }

    func testInstallStashesStateRetrievableViaStateStore() throws {
        let fakeAd = FakeRewardedAd()

        let returnedState = try XCTUnwrap(
            RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)
        )
        let stashedState = try XCTUnwrap(RewardVerification.stateStore.retrieve(for: fakeAd))

        XCTAssertTrue(returnedState === stashedState,
                      "RewardVerification.stateStore.retrieve(for:) must return the exact instance produced by install")
    }

    func testInstallGeneratesUniqueClientTransactionIDPerCall() {
        let firstAd = FakeRewardedAd()
        let secondAd = FakeRewardedAd()

        let firstState = RewardVerification.Setup.install(
            on: firstAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID
        )
        let secondState = RewardVerification.Setup.install(
            on: secondAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID
        )

        XCTAssertNotEqual(firstState?.clientTransactionID, secondState?.clientTransactionID)
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

        let firstState = try XCTUnwrap(
            RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)
        )
        let secondState = try XCTUnwrap(
            RewardVerification.Setup.install(on: fakeAd, apiKey: Self.testAPIKey, appUserID: Self.testAppUserID)
        )
        let stashedState = try XCTUnwrap(RewardVerification.stateStore.retrieve(for: fakeAd))

        XCTAssertFalse(firstState === secondState)
        XCTAssertTrue(stashedState === secondState)
    }

    // MARK: - makeCustomRewardText

    func testMakeCustomRewardTextProducesValidJSONWithExpectedKeys() throws {
        let text = try XCTUnwrap(RewardVerification.Setup.makeCustomRewardText(
            apiKey: "key_123",
            clientTransactionID: "txn_456"
        ))
        let payload = try Self.parseJSONObject(text)

        XCTAssertEqual(payload, ["api_key": "key_123", "client_transaction_id": "txn_456"])
    }

    func testMakeCustomRewardTextProducesSortedKeys() throws {
        let text = try XCTUnwrap(RewardVerification.Setup.makeCustomRewardText(
            apiKey: "key_123",
            clientTransactionID: "txn_456"
        ))

        // .sortedKeys guarantees stable byte ordering — keep tests / logs / snapshots deterministic.
        XCTAssertEqual(text, "{\"api_key\":\"key_123\",\"client_transaction_id\":\"txn_456\"}")
    }

    // MARK: - Helpers

    private static func parseJSONObject(_ string: String) throws -> [String: String] {
        let data = try XCTUnwrap(string.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: String])
    }
}

// MARK: - Test doubles

@available(iOS 15.0, *)
private final class FakeRewardedAd: RewardVerification.CapableAd {
    var serverSideVerificationOptions: GoogleMobileAds.ServerSideVerificationOptions?
}

#endif
