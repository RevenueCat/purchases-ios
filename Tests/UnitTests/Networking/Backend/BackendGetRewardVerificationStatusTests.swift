//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetRewardVerificationStatusTests.swift
//
//  Created by Pol Miro on 20/04/2026.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class BackendGetRewardVerificationStatusTests: BaseBackendTests {

    private static let clientTransactionID = "AABBCCDD-1111-2222-3333-444455556666"

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    // MARK: - HTTP path / wiring

    func testGetRewardVerificationStatusCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: Self.verifiedResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testGetRewardVerificationStatusSendsAdUnitIDQueryParameter() throws {
        self.httpClient.disableSnapshotTesting()
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: "ca-app-pub-123/456"
            ),
            response: .init(statusCode: .success, response: Self.pendingResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: "ca-app-pub-123/456",
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        let url = try XCTUnwrap(self.httpClient.calls.first?.request.path.url(preferIAMPath: false))
        expect(url.absoluteString) == "https://api.revenuecat.com/v1/subscribers/\(Self.userID)"
            + "/ads/reward_verifications/\(Self.clientTransactionID)?ad_unit_id=ca-app-pub-123/456"
    }

    func testGetRewardVerificationStatusOmitsEmptyAdUnitID() throws {
        self.httpClient.disableSnapshotTesting()
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: Self.pendingResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: "",
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        let url = try XCTUnwrap(self.httpClient.calls.first?.request.path.url(preferIAMPath: false))
        expect(url.query).to(beNil())
    }

    // MARK: - Response shapes

    func testGetRewardVerificationStatusVerified() throws {
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: Self.verifiedResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        let payload = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 10))
        expect(response.status) == .verified(.virtualCurrency(payload))
    }

    func testGetRewardVerificationStatusPending() throws {
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: Self.pendingResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .pending
    }

    func testGetRewardVerificationStatusFailed() throws {
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: Self.failedResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .failed(.init(reason: nil, message: nil))
    }

    func testGetRewardVerificationStatusFailedForwardsReasonAndMessage() throws {
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: Self.failedWithReasonResponse)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .failed(.init(
            reason: "no_access",
            message: "AdMob server-side reward verification is not enabled for this app."
        ))
    }

    func testGetRewardVerificationStatusUnknownStatusDecodesAsUnknown() throws {
        // Defence-in-depth: future backend additions must not break decode.
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: ["status": "some_future_state"])
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.status) == .unknown

        expect(self.logger.messages.map(\.message)).to(
            containElementSatisfying {
                $0.contains(
                    Strings.backendError.unknown_reward_verification_status(status: "some_future_state").description
                )
            }
        )
    }

    func testGetRewardVerificationStatusStampsEmbeddedCustomerInfoWithVerificationResult() throws {
        self.httpClient.disableSnapshotTesting()
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success,
                            response: Self.verifiedWithSubscriberResponse,
                            verificationResult: .verified)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        let customerInfo = try XCTUnwrap(result?.value?.customerInfo)
        expect(customerInfo.originalAppUserId) == Self.userID
        expect(customerInfo.entitlements.verification) == .verified
        expect(customerInfo.entitlements["pro"]?.verification) == .verified
    }

    // MARK: - Error handling

    func testGetRewardVerificationStatusFailSendsError() {
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(error: .unexpectedResponse(nil))
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        expect(result).to(beFailure())
    }

    func testGetRewardVerificationStatusNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil,
                completion: completed
            )
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    // MARK: - Empty user ID

    func testGetRewardVerificationStatusSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: "",
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetRewardVerificationStatusCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: "",
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }

    func testGetRewardVerificationStatusSkipsBackendCallIfClientTransactionIDIsEmpty() {
        waitUntil { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: "",
                adUnitID: nil
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetRewardVerificationStatusCallsCompletionWithErrorIfClientTransactionIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: "",
                adUnitID: nil
            ) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingClientTransactionID()
    }

    // MARK: - Caching / dedupe

    func testGetRewardVerificationStatusDedupesConcurrentCallsForSameTransactionID() {
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success,
                            response: Self.pendingResponse,
                            delay: .milliseconds(10))
        )

        self.adsAPI.getRewardVerificationStatus(
            appUserID: Self.userID,
            clientTransactionID: Self.clientTransactionID,
            adUnitID: nil
        ) { _ in }

        self.adsAPI.getRewardVerificationStatus(
            appUserID: Self.userID,
            clientTransactionID: Self.clientTransactionID,
            adUnitID: nil
        ) { _ in }

        // Both calls share a cache key (UUID is per-ad), so only one HTTP request fires.
        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))
    }

    func testGetRewardVerificationStatusDoesNotDedupeAcrossDifferentTransactionIDs() {
        let secondTransactionID = "ZZZZZZZZ-9999-8888-7777-666655554444"
        let response = MockHTTPClient.Response(
            statusCode: .success,
            response: Self.pendingResponse
        )

        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: response
        )
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: secondTransactionID,
                adUnitID: nil
            ),
            response: response
        )

        self.adsAPI.getRewardVerificationStatus(
            appUserID: Self.userID,
            clientTransactionID: Self.clientTransactionID,
            adUnitID: nil
        ) { _ in }
        self.adsAPI.getRewardVerificationStatus(
            appUserID: Self.userID,
            clientTransactionID: secondTransactionID,
            adUnitID: nil
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
        expect(self.httpClient.calls).toNever(haveCount(3))
    }

    func testGetRewardVerificationStatusSequentialCallsForSameTransactionIDReissueRequest() {
        // The retry loop in the adapter polls the same UUID multiple times.
        // Once a request finishes, its callbacks are removed from the cache,
        // so the next call must hit the network again.
        self.httpClient.mock(
            requestPath: .rewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ),
            response: .init(statusCode: .success, response: Self.pendingResponse)
        )

        waitUntil { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ) { _ in completed() }
        }

        waitUntil { completed in
            self.adsAPI.getRewardVerificationStatus(
                appUserID: Self.userID,
                clientTransactionID: Self.clientTransactionID,
                adUnitID: nil
            ) { _ in completed() }
        }

        expect(self.httpClient.calls).to(haveCount(2))
    }
}

private extension BackendGetRewardVerificationStatusTests {

    static let verifiedResponse: [String: Any] = [
        "status": "verified",
        "reward": [
            "type": "virtual_currency",
            "code": "coins",
            "amount": 10
        ]
    ]
    static let verifiedWithSubscriberResponse: [String: Any] = [
        "status": "verified",
        "reward": [
            "type": "entitlement",
            "identifier": "pro",
            "expires_at": "2026-06-16T12:00:00Z"
        ],
        "more_rewards": [] as [Any],
        "request_date": "2026-05-16T12:00:00Z",
        "request_date_ms": 1778932800000,
        "subscriber": [
            "first_seen": "2026-05-16T12:00:00Z",
            "original_app_user_id": BaseBackendTests.userID,
            "other_purchases": [:] as [String: Any],
            "subscriptions": [
                "rc_ad_pro": [
                    "purchase_date": "2026-05-16T12:00:00Z",
                    "expires_date": "2026-06-16T12:00:00Z",
                    "period_type": "normal",
                    "store": "promotional"
                ]
            ],
            "entitlements": [
                "pro": [
                    "product_identifier": "rc_ad_pro",
                    "purchase_date": "2026-05-16T12:00:00Z",
                    "expires_date": "2026-06-16T12:00:00Z"
                ]
            ]
        ] as [String: Any]
    ]
    static let pendingResponse: [String: Any] = ["status": "pending"]
    static let failedResponse: [String: Any] = ["status": "failed"]
    static let failedWithReasonResponse: [String: Any] = [
        "status": "failed",
        "reward": NSNull(),
        "failure_reason": "no_access",
        "message": "AdMob server-side reward verification is not enabled for this app."
    ]

}
