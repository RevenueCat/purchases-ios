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

        expect(response.operationSessionId) == "op_session_id"
        expect(response.checkoutUrl) == URL(string: "https://checkout.stripe.com/c/pay/cs_test_123")
        expect(response.successUrl) == URL(string: "\(Self.returnEndpoint)?status=success")
        expect(response.cancelUrl) == URL(string: "\(Self.returnEndpoint)?status=cancel")
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

}

private extension BackendPostHostedCheckoutTests {

    static let returnEndpoint = "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return"

    static let response: [String: Any] = [
        "operation_session_id": "op_session_id",
        "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_123",
        "success_url": "\(returnEndpoint)?status=success",
        "cancel_url": "\(returnEndpoint)?status=cancel"
    ]

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
        self.webBilling.postHostedCheckout(
            appUserID: appUserID,
            packageID: packageID,
            presentedOfferingIdentifier: offeringID,
            externalPurchaseTokenID: tokenID,
            completion: completion
        )
    }

}
