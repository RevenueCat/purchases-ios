//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostCreateTicketOperationTests.swift
//
//  Created by Rosie Watson on 11/10/2025

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class PostCreateTicketOperationTests: BaseBackendTests {

    private var appUserID: String!
    private var customerEmail: String!
    private var ticketDescription: String!

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.appUserID = "test_user_123"
        self.customerEmail = "test@example.com"
        self.ticketDescription = "Test ticket description"
    }

    func testPostCreateTicketOperationWithValidData() {
        let operation = self.createOperation()
        var receivedResult: Result<CreateTicketResponse, BackendError>?

        operation.begin {
            // Operation completed
        }

        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": true])
        )

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if let call = self.httpClient.calls.first {
            expect(call.path) == .postCreateTicket
            expect(call.request?.httpMethod) == "POST"
        }
    }

    func testPostCreateTicketOperationWithEmptyAppUserID() {
        self.appUserID = ""
        let operation = self.createOperation()

        var receivedResult: Result<CreateTicketResponse, BackendError>?
        let expectation = self.expectation(description: "completion called")

        operation.begin {
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1)
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testPostCreateTicketOperationSendsCorrectBody() {
        let operation = self.createOperation()

        operation.begin {
            // Operation completed
        }

        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": true])
        )

        expect(self.httpClient.calls.count).toEventually(equal(1))

        if let call = self.httpClient.calls.first,
           let bodyData = call.request?.httpBody,
           let bodyDict = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            expect(bodyDict["app_user_id"] as? String) == self.appUserID
            expect(bodyDict["customer_email"] as? String) == self.customerEmail
            expect(bodyDict["issue_description"] as? String) == self.ticketDescription
        } else {
            fail("Expected request body to be present")
        }
    }

    func testPostCreateTicketOperationHandlesSuccessResponse() {
        var receivedResult: Result<CreateTicketResponse, BackendError>?
        let expectation = self.expectation(description: "response handler called")

        let operation = PostCreateTicketOperation(
            configuration: self.createConfiguration(),
            customerEmail: self.customerEmail,
            ticketDescription: self.ticketDescription,
            responseHandler: { result in
                receivedResult = result
                expectation.fulfill()
            }
        )

        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": true])
        )

        operation.begin {
            // Operation completed
        }

        self.waitForExpectations(timeout: 1)

        expect(receivedResult).toNot(beNil())
        if case .success(let response) = receivedResult {
            expect(response.sent) == true
        } else {
            fail("Expected success result")
        }
    }

    func testPostCreateTicketOperationHandlesFailureResponse() {
        var receivedResult: Result<CreateTicketResponse, BackendError>?
        let expectation = self.expectation(description: "response handler called")

        let operation = PostCreateTicketOperation(
            configuration: self.createConfiguration(),
            customerEmail: self.customerEmail,
            ticketDescription: self.ticketDescription,
            responseHandler: { result in
                receivedResult = result
                expectation.fulfill()
            }
        )

        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(statusCode: .success, response: ["sent": false])
        )

        operation.begin {
            // Operation completed
        }

        self.waitForExpectations(timeout: 1)

        expect(receivedResult).toNot(beNil())
        if case .success(let response) = receivedResult {
            expect(response.sent) == false
        } else {
            fail("Expected success result with sent=false")
        }
    }

    func testPostCreateTicketOperationHandlesNetworkError() {
        var receivedResult: Result<CreateTicketResponse, BackendError>?
        let expectation = self.expectation(description: "response handler called")

        let operation = PostCreateTicketOperation(
            configuration: self.createConfiguration(),
            customerEmail: self.customerEmail,
            ticketDescription: self.ticketDescription,
            responseHandler: { result in
                receivedResult = result
                expectation.fulfill()
            }
        )

        self.httpClient.mock(
            requestPath: .postCreateTicket,
            response: .init(error: .networkError(URLError(.notConnectedToInternet)))
        )

        operation.begin {
            // Operation completed
        }

        self.waitForExpectations(timeout: 1)

        expect(receivedResult).toNot(beNil())
        if case .failure(let error) = receivedResult {
            expect(error).toNot(beNil())
        } else {
            fail("Expected failure result")
        }
    }

    // MARK: - Helper Methods

    private func createOperation() -> PostCreateTicketOperation {
        return PostCreateTicketOperation(
            configuration: self.createConfiguration(),
            customerEmail: self.customerEmail,
            ticketDescription: self.ticketDescription,
            responseHandler: nil
        )
    }

    private func createConfiguration() -> NetworkOperation.UserSpecificConfiguration {
        return NetworkOperation.UserSpecificConfiguration(
            httpClient: self.httpClient,
            appUserID: self.appUserID
        )
    }
}
