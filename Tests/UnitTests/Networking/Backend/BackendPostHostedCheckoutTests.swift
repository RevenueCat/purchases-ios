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
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        self.postHostedCheckout(appUserID: Self.userID, packageID: Self.packageID, offeringID: Self.offeringID) { _ in }
        self.postHostedCheckout(appUserID: Self.userID, packageID: "$rc_annual", offeringID: Self.offeringID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testRequestsForDifferentOfferingsAreNotReused() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        self.postHostedCheckout(appUserID: Self.userID, packageID: Self.packageID, offeringID: Self.offeringID) { _ in }
        self.postHostedCheckout(appUserID: Self.userID, packageID: Self.packageID, offeringID: "promo") { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testRequestsForDifferentUsersAreNotReused() {
        self.httpClient.mock(
            requestPath: .postHostedCheckout,
            response: .init(statusCode: .success, response: Self.response)
        )

        self.postHostedCheckout(appUserID: Self.userID, packageID: Self.packageID, offeringID: Self.offeringID) { _ in }
        self.postHostedCheckout(appUserID: "another_user",
                                packageID: Self.packageID,
                                offeringID: Self.offeringID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
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
            self.postHostedCheckout(appUserID: "", packageID: Self.packageID, offeringID: Self.offeringID) {
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

    /// The same request throughout, so that a test only spells out what it is varying.
    func postHostedCheckout(completion: @escaping WebBillingAPI.HostedCheckoutResponseHandler) {
        self.postHostedCheckout(
            appUserID: BackendPostHostedCheckoutTests.userID,
            packageID: BackendPostHostedCheckoutTests.packageID,
            offeringID: BackendPostHostedCheckoutTests.offeringID,
            completion: completion
        )
    }

    func postHostedCheckout(
        appUserID: String,
        packageID: String,
        offeringID: String,
        completion: @escaping WebBillingAPI.HostedCheckoutResponseHandler
    ) {
        self.webBilling.postHostedCheckout(
            appUserID: appUserID,
            packageID: packageID,
            presentedOfferingIdentifier: offeringID,
            completion: completion
        )
    }

}
