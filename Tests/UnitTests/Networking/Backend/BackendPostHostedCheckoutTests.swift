//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostHostedCheckoutTests.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendPostHostedCheckoutTests: BaseBackendTests {

    private static let packageID = "$rc_monthly"
    private static let offeringID = "default"
    private static let tokenID = "eptoken_123"
    private static let previousOperationSessionID = "op_session_previous"

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testSendsTheExpectedRequest() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = waitUntilValue { completed in
            self.postHostedCheckout(completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    /// The purchase has to reach the backend with the same attribution a StoreKit purchase from the same
    /// paywall would carry, so placement, targeting rule and paywall all travel with it.
    func testSendsThePresentedOfferingContext() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = waitUntilValue { completed in
            self.postHostedCheckout(
                appUserID: Self.userID,
                packageID: Self.packageID,
                presentedOfferingContext: .init(offeringIdentifier: Self.offeringID,
                                                placementIdentifier: "onboarding",
                                                targetingContext: .init(revision: 3, ruleId: "rule_abc")),
                paywall: .init(paywallID: "pw_789",
                               sessionID: "pws_012",
                               workflowID: "wf_123",
                               stepID: "step_456"),
                tokenID: Self.tokenID,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testIsNotDelayed() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = waitUntilValue { completed in
            self.postHostedCheckout(completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    func testReturnsTheDecodedResponse() throws {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = waitUntilValue { completed in
            self.postHostedCheckout(completion: completed)
        }

        let response = try XCTUnwrap(result?.value)

        expect(response.operationSessionID) == "op_session_id"
        expect(response.outcome) == .created(Self.page)
    }

    /// Asking to resume a session carries its ID, so that the backend can hand it back rather than create a
    /// second one the customer could pay for as well.
    func testSendsThePreviousSession() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = waitUntilValue { completed in
            self.postHostedCheckout(appUserID: Self.userID,
                                    packageID: Self.packageID,
                                    offeringID: Self.offeringID,
                                    tokenID: Self.tokenID,
                                    previousOperationSessionID: Self.previousOperationSessionID,
                                    completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    /// Creating a checkout session answers `201`, so that is the status the flow actually has to read.
    func testAcceptsTheCreatedStatus() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .createdSuccess, response: Self.response)
        )

        let result = waitUntilValue { completed in
            self.postHostedCheckout(completion: completed)
        }

        expect(result).to(beSuccess())
        expect(result?.value?.operationSessionID) == "op_session_id"
    }

    /// A second tap while the first request is still running must not open a second checkout session.
    func testIdenticalRequestsInFlightAreReusedForASingleCall() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response, delay: .milliseconds(10))
        )

        self.postHostedCheckout { _ in }
        self.postHostedCheckout { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))
    }

    func testRequestsForDifferentPackagesAreNotReused() {
        self.expectTwoCalls(varying: { packageID in
            self.postHostedCheckout(appUserID: Self.userID,
                                    packageID: packageID,
                                    offeringID: Self.offeringID,
                                    tokenID: Self.tokenID) { _ in }
        }, from: Self.packageID, to: "$rc_annual")
    }

    func testRequestsForDifferentOfferingsAreNotReused() {
        self.expectTwoCalls(varying: { offeringID in
            self.postHostedCheckout(appUserID: Self.userID,
                                    packageID: Self.packageID,
                                    offeringID: offeringID,
                                    tokenID: Self.tokenID) { _ in }
        }, from: Self.offeringID, to: "promo")
    }

    func testRequestsForDifferentUsersAreNotReused() {
        self.expectTwoCalls(varying: { appUserID in
            self.postHostedCheckout(appUserID: appUserID,
                                    packageID: Self.packageID,
                                    offeringID: Self.offeringID,
                                    tokenID: Self.tokenID) { _ in }
        }, from: Self.userID, to: "another_user")
    }

    /// Sharing these would attribute one purchase to the other's Apple token.
    func testRequestsForDifferentTokensAreNotReused() {
        self.expectTwoCalls(varying: { tokenID in
            self.postHostedCheckout(appUserID: Self.userID,
                                    packageID: Self.packageID,
                                    offeringID: Self.offeringID,
                                    tokenID: tokenID) { _ in }
        }, from: Self.tokenID, to: "eptoken_456")
    }

    /// Each asks the backend about a different session, which it could hand back.
    func testRequestsForDifferentPreviousSessionsAreNotReused() {
        // What the request carries is covered by `testSendsThePreviousSession`.
        self.httpClient.disableSnapshotTesting()

        self.expectTwoCalls(varying: { previousOperationSessionID in
            self.postHostedCheckout(appUserID: Self.userID,
                                    packageID: Self.packageID,
                                    offeringID: Self.offeringID,
                                    tokenID: Self.tokenID,
                                    previousOperationSessionID: previousOperationSessionID) { _ in }
        }, from: Self.previousOperationSessionID, to: "op_session_other")
    }

    func testSendsNoTokenWhenThereIsNone() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        let result = waitUntilValue { completed in
            self.postHostedCheckout(appUserID: Self.userID,
                                    packageID: Self.packageID,
                                    offeringID: Self.offeringID,
                                    tokenID: nil,
                                    completion: completed)
        }

        expect(result).to(beSuccess())
    }

    func testForwardsANetworkError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(requestPath: .postHostedCheckout, response: .init(error: mockedError))

        let result = waitUntilValue { completed in
            self.postHostedCheckout(completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testSkipsTheCallWhenTheAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.postHostedCheckout(appUserID: "",
                                    packageID: Self.packageID,
                                    offeringID: Self.offeringID,
                                    tokenID: Self.tokenID) {
                completed($0.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
        expect(self.httpClient.calls).to(beEmpty())
    }

    // MARK: - Outcome

    /// A backend that does not send an outcome yet only ever creates sessions.
    func testDecodesAResponseWithoutAnOutcomeAsCreated() throws {
        let response = try Self.decode(Self.response)

        expect(response.outcome) == .created(Self.page)
    }

    func testDecodesACreatedSession() throws {
        let response = try Self.decode(Self.response.merging(["outcome": "created"]) { $1 })

        expect(response.outcome) == .created(Self.page)
    }

    func testDecodesAResumedSession() throws {
        let response = try Self.decode(Self.response.merging(["outcome": "resumed"]) { $1 })

        expect(response.operationSessionID) == "op_session_id"
        expect(response.outcome) == .resumed(Self.page)
    }

    /// There is nothing left to present once the session succeeded, so the backend need not send its pages.
    func testDecodesASucceededSessionWithoutItsPages() throws {
        let response = try Self.decode([
            "operation_session_id": "op_session_id",
            "outcome": "succeeded"
        ])

        expect(response.outcome) == .succeeded
    }

    /// Presenting the session it sent is what the backend did before it had an outcome to tell.
    func testDecodesAnUnrecognizedOutcomeAsCreated() throws {
        let response = try Self.decode(Self.response.merging(["outcome": "something_new"]) { $1 })

        expect(response.outcome) == .created(Self.page)
    }

    func testFailsToDecodeAResumedSessionWithoutItsPages() {
        expect(try Self.decode([
            "operation_session_id": "op_session_id",
            "outcome": "resumed"
        ])).to(throwError())
    }

}

private extension BackendPostHostedCheckoutTests {

    static let returnEndpoint = "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return"

    static let response: [String: Any] = [
        "operation_session_id": "op_session_id",
        "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_123",
        "success_url": "\(returnEndpoint)?status=success",
        "cancel_url": "\(returnEndpoint)?status=cancel"
    ]

    static let page = HostedCheckoutResponse.Page(
        checkoutURL: URL(string: "https://checkout.stripe.com/c/pay/cs_test_123")!,
        successURL: URL(string: "\(returnEndpoint)?status=success")!,
        cancelURL: URL(string: "\(returnEndpoint)?status=cancel")!
    )

    static func decode(_ response: [String: Any]) throws -> HostedCheckoutResponse {
        return try HostedCheckoutResponse.create(with: JSONSerialization.data(withJSONObject: response))
    }

    /// Fires `request` twice, changing one input, and expects both to reach the network rather than
    /// being coalesced into one.
    func expectTwoCalls(varying request: (String) -> Void, from first: String, to second: String) {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: BackendPostHostedCheckoutTests.response)
        )

        request(first)
        request(second)

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    /// The same request throughout, so that a test only spells out what it is varying.
    func postHostedCheckout(completion: @escaping WebBillingAPI.HostedCheckoutResponseHandler) {
        self.postHostedCheckout(
            appUserID: BackendPostHostedCheckoutTests.userID,
            packageID: BackendPostHostedCheckoutTests.packageID,
            offeringID: BackendPostHostedCheckoutTests.offeringID,
            tokenID: BackendPostHostedCheckoutTests.tokenID,
            completion: completion
        )
    }

    func postHostedCheckout(
        appUserID: String,
        packageID: String,
        offeringID: String,
        tokenID: String?,
        completion: @escaping WebBillingAPI.HostedCheckoutResponseHandler
    ) {
        self.postHostedCheckout(
            appUserID: appUserID,
            packageID: packageID,
            offeringID: offeringID,
            tokenID: tokenID,
            previousOperationSessionID: nil,
            completion: completion
        )
    }

    // swiftlint:disable:next function_parameter_count
    func postHostedCheckout(
        appUserID: String,
        packageID: String,
        offeringID: String,
        tokenID: String?,
        previousOperationSessionID: String?,
        completion: @escaping WebBillingAPI.HostedCheckoutResponseHandler
    ) {
        self.webBilling.postHostedCheckout(
            appUserID: appUserID,
            packageID: packageID,
            presentedOfferingContext: .init(offeringIdentifier: offeringID),
            paywall: nil,
            externalPurchaseTokenID: tokenID,
            previousOperationSessionID: previousOperationSessionID,
            completion: completion
        )
    }

    // swiftlint:disable:next function_parameter_count
    func postHostedCheckout(
        appUserID: String,
        packageID: String,
        presentedOfferingContext: PresentedOfferingContext,
        paywall: PostHostedCheckoutOperation.Paywall?,
        tokenID: String?,
        completion: @escaping WebBillingAPI.HostedCheckoutResponseHandler
    ) {
        self.webBilling.postHostedCheckout(
            appUserID: appUserID,
            packageID: packageID,
            presentedOfferingContext: presentedOfferingContext,
            paywall: paywall,
            externalPurchaseTokenID: tokenID,
            previousOperationSessionID: nil,
            completion: completion
        )
    }

}
