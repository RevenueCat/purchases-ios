//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostCreateTicketTests.swift
//
//  Created by Rosie Watson on 11/10/2025

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

final class BackendPostCreateTicketTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostCreateTicketWithValidData() {
        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": true])
        )

        var receivedResult: Result<CreateTicketResponse, BackendError>?

        waitUntil { completed in
            self.backend.customerCenterConfig.postCreateTicket(
                appUserID: Self.userID,
                customerEmail: "test@example.com",
                ticketDescription: "Test ticket description"
            ) { result in
                receivedResult = result
                completed()
            }
        }

        expect(self.httpClient.calls).to(haveCount(1))
        expect(receivedResult).toNot(beNil())

        if case .success(let response) = receivedResult {
            expect(response.sent) == true
        } else {
            fail("Expected success result")
        }
    }

    func testPostCreateTicketWithFailedResponse() {
        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": false])
        )

        var receivedResult: Result<CreateTicketResponse, BackendError>?

        waitUntil { completed in
            self.backend.customerCenterConfig.postCreateTicket(
                appUserID: Self.userID,
                customerEmail: "test@example.com",
                ticketDescription: "Test ticket description"
            ) { result in
                receivedResult = result
                completed()
            }
        }

        expect(self.httpClient.calls).to(haveCount(1))
        expect(receivedResult).toNot(beNil())

        if case .success(let response) = receivedResult {
            expect(response.sent) == false
        } else {
            fail("Expected success result with sent=false")
        }
    }

    func testPostCreateTicketWithEmptyAppUserID() {
        var receivedResult: Result<CreateTicketResponse, BackendError>?

        waitUntil { completed in
            self.backend.customerCenterConfig.postCreateTicket(
                appUserID: "",
                customerEmail: "test@example.com",
                ticketDescription: "Test ticket description"
            ) { result in
                receivedResult = result
                completed()
            }
        }

        expect(self.httpClient.calls).to(beEmpty())
        expect(receivedResult).toNot(beNil())

        if case .failure(let error) = receivedResult {
            expect(error) == .missingAppUserID()
        } else {
            fail("Expected failure result with missing app user ID")
        }
    }

    func testPostCreateTicketWithNetworkError() {
        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(error: .networkError(URLError(.notConnectedToInternet)))
        )

        var receivedResult: Result<CreateTicketResponse, BackendError>?

        waitUntil { completed in
            self.backend.customerCenterConfig.postCreateTicket(
                appUserID: Self.userID,
                customerEmail: "test@example.com",
                ticketDescription: "Test ticket description"
            ) { result in
                receivedResult = result
                completed()
            }
        }

        expect(self.httpClient.calls).to(haveCount(1))
        expect(receivedResult).toNot(beNil())

        if case .failure = receivedResult {
            // Success - we got a failure as expected
        } else {
            fail("Expected failure result")
        }
    }

    func testPostCreateTicketSendsCorrectParameters() throws {
        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": true])
        )

        let testEmail = "test@example.com"
        let testDescription = "Test ticket description"

        waitUntil { completed in
            self.backend.customerCenterConfig.postCreateTicket(
                appUserID: Self.userID,
                customerEmail: testEmail,
                ticketDescription: testDescription
            ) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(haveCount(1))

        if let call = self.httpClient.calls.first,
           let bodyDict = try call.request.requestBody?.asJSONDictionary() {
            expect(bodyDict["app_user_id"] as? String) == Self.userID
            expect(bodyDict["customer_email"] as? String) == testEmail
            expect(bodyDict["issue_description"] as? String) == testDescription
        } else {
            fail("Expected request body to be present")
        }
    }

    func testPostCreateTicketUsesCorrectHTTPMethod() throws {
        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": true])
        )

        waitUntil { completed in
            self.backend.customerCenterConfig.postCreateTicket(
                appUserID: Self.userID,
                customerEmail: "test@example.com",
                ticketDescription: "Test ticket description"
            ) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(haveCount(1))

        if let call = self.httpClient.calls.first {
            let path = try XCTUnwrap(call.request.path as? HTTPRequest.Path)
            expect(path) == .postCreateTicket
            expect(call.request.method.httpMethod) == "POST"
        } else {
            fail("Expected HTTP call to be made")
        }
    }
}
