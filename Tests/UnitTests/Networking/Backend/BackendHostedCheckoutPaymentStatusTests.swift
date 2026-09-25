//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendHostedCheckoutPaymentStatusTests.swift
//
//  Created by Antonio Pallares on 25/9/26.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendHostedCheckoutPaymentStatusTests: BaseBackendTests {

    private static let operationSessionID = "opsession_123"

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testSendsTheExpectedRequest() {
        self.mockPaymentStatus("open")

        let result = waitUntilValue { completed in
            self.getPaymentStatus(completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testIsNotDelayed() {
        self.mockPaymentStatus("open")

        let result = waitUntilValue { completed in
            self.getPaymentStatus(completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == JitterableDelay.none
    }

    // MARK: - Decoding

    func testReadsAnOpenPayment() throws {
        self.mockPaymentStatus("open")

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getPaymentStatus(completion: completed)
        }?.value)

        expect(response.paymentStatus) == .open
    }

    func testReadsAProcessingPayment() throws {
        self.mockPaymentStatus("processing")

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getPaymentStatus(completion: completed)
        }?.value)

        expect(response.paymentStatus) == .processing
    }

    func testReadsAnUnknownPayment() throws {
        self.mockPaymentStatus("unknown")

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getPaymentStatus(completion: completed)
        }?.value)

        expect(response.paymentStatus) == .unknown
    }

    /// A status a newer backend adds must not read as an answer this version cannot vouch for.
    func testReadsAnUnrecognizedPaymentStatusAsUnknown() throws {
        self.mockPaymentStatus("something_new")

        let response = try XCTUnwrap(waitUntilValue { completed in
            self.getPaymentStatus(completion: completed)
        }?.value)

        expect(response.paymentStatus) == .unknown
    }

    // MARK: - Failures

    func testForwardsANetworkError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(requestPath: Self.path, response: .init(error: mockedError))

        let result = waitUntilValue { completed in
            self.getPaymentStatus(completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testSkipsTheCallWhenTheAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.getPaymentStatus(appUserID: "") {
                completed($0.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
        expect(self.httpClient.calls).to(beEmpty())
    }

    // MARK: - Reuse

    func testIdenticalRequestsInFlightAreReusedForASingleCall() {
        self.httpClient.mock(
            requestPath: Self.path,
            response: .init(statusCode: .success,
                            response: ["payment_status": "open"],
                            delay: .milliseconds(10))
        )

        self.getPaymentStatus { _ in }
        self.getPaymentStatus { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
        expect(self.httpClient.calls).toNever(haveCount(2))
    }

}

private extension BackendHostedCheckoutPaymentStatusTests {

    static let path = HTTPRequest.WebBillingPath.getHostedCheckoutPaymentStatus(
        operationSessionID: operationSessionID,
        appUserID: userID
    )

    func mockPaymentStatus(_ paymentStatus: String) {
        self.httpClient.mock(requestPath: Self.path,
                             response: .init(statusCode: .success, response: ["payment_status": paymentStatus]))
    }

    func getPaymentStatus(completion: @escaping WebBillingAPI.CheckoutPaymentStatusResponseHandler) {
        self.getPaymentStatus(appUserID: BackendHostedCheckoutPaymentStatusTests.userID, completion: completion)
    }

    func getPaymentStatus(appUserID: String,
                          completion: @escaping WebBillingAPI.CheckoutPaymentStatusResponseHandler) {
        self.webBilling.getHostedCheckoutPaymentStatus(
            appUserID: appUserID,
            operationSessionID: BackendHostedCheckoutPaymentStatusTests.operationSessionID,
            completion: completion
        )
    }

}
