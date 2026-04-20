//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetWorkflowTests.swift

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetWorkflowTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.httpClient.disableSnapshotTesting()
    }

    func testGetWorkflowCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID),
            response: .init(statusCode: .success, response: Self.workflowResponse)
        )

        let result = waitUntilValue { completed in
            self.offerings.getWorkflow(appUserID: Self.userID,
                                       workflowID: Self.workflowID,
                                       completion: completed)
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testGetWorkflowCachesForSameUserAndWorkflowID() {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID),
            response: .init(statusCode: .success,
                            response: Self.workflowResponse,
                            delay: .milliseconds(10))
        )

        self.offerings.getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID) { _ in }
        self.offerings.getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetWorkflowDoesNotCacheForDifferentWorkflowIDs() {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.workflowResponse)
        let otherWorkflowID = "other_workflow"

        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID),
            response: response
        )
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowID: otherWorkflowID),
            response: response
        )

        self.offerings.getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID) { _ in }
        self.offerings.getWorkflow(appUserID: Self.userID, workflowID: otherWorkflowID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetWorkflowDoesNotCacheForDifferentUserIDs() {
        let response = MockHTTPClient.Response(statusCode: .success, response: Self.workflowResponse)
        let otherUserID = "user_2"

        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID),
            response: response
        )
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: otherUserID, workflowID: Self.workflowID),
            response: response
        )

        self.offerings.getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID) { _ in }
        self.offerings.getWorkflow(appUserID: otherUserID, workflowID: Self.workflowID) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(2))
    }

    func testGetWorkflowNetworkErrorPropagates() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.offerings.getWorkflow(appUserID: Self.userID,
                                       workflowID: Self.workflowID,
                                       completion: completed)
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetWorkflowEmptyAppUserIDReturnsError() {
        let result = waitUntilValue { completed in
            self.offerings.getWorkflow(appUserID: "", workflowID: Self.workflowID, completion: completed)
        }

        expect(self.httpClient.calls).to(beEmpty())
        expect(result?.error) == .missingAppUserID()
    }

    func testGetWorkflowDecodesResponse() throws {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowID: Self.workflowID),
            response: .init(statusCode: .success, response: Self.workflowResponse)
        )

        let result = waitUntilValue { completed in
            self.offerings.getWorkflow(appUserID: Self.userID,
                                       workflowID: Self.workflowID,
                                       completion: completed)
        }

        let response = try XCTUnwrap(result?.value)
        expect(response.workflow.id) == "workflow_1"
        expect(response.workflow.steps).to(haveCount(1))
        expect(response.workflow.steps.first?.id) == "step_1"
        expect(response.workflow.steps.first?.screenId) == "screen_1"
        expect(response.workflow.screens.keys).to(contain("screen_1"))
        expect(response.workflow.screens["screen_1"]?.offeringId) == "offering_a"
        expect(response.workflow.screens["screen_1"]?.templateName) == "componentsTest"
        expect(response.workflow.screens["screen_1"]?.revision) == 3
        expect(response.workflow.screens["screen_1"]?.defaultLocale) == "en_US"
        expect(response.enrolledVariants) == ["variant_key": "variant_value"]
    }

}

private extension BackendGetWorkflowTests {

    static let workflowID = "offering_a"

    static let workflowResponse: [String: Any] = [
        "workflow": [
            "id": "workflow_1",
            "initial_step_id": "step_1",
            "steps": [
                ["id": "step_1", "screen_id": "screen_1"] as [String: Any]
            ],
            "screens": [
                "screen_1": [
                    "offering_id": "offering_a",
                    "template_name": "componentsTest",
                    "asset_base_url": "https://assets.pawwalls.com",
                    "revision": 3,
                    "components_localizations": [:] as [String: Any],
                    "default_locale": "en_US",
                    "components_config": [
                        "base": [
                            "stack": [
                                "type": "stack",
                                "components": [] as [Any],
                                "dimension": [
                                    "type": "vertical",
                                    "alignment": "center",
                                    "distribution": "center"
                                ] as [String: Any],
                                "size": [
                                    "width": ["type": "fill"] as [String: Any],
                                    "height": ["type": "fill"] as [String: Any]
                                ] as [String: Any],
                                "margin": [:] as [String: Any],
                                "padding": [:] as [String: Any],
                                "spacing": 0
                            ] as [String: Any],
                            "background": [
                                "type": "color",
                                "value": [
                                    "light": ["type": "hex", "value": "#220000ff"] as [String: Any]
                                ] as [String: Any]
                            ] as [String: Any]
                        ] as [String: Any]
                    ] as [String: Any]
                ] as [String: Any]
            ] as [String: Any],
            "ui_config": [
                "app": ["colors": [:] as [String: Any], "fonts": [:] as [String: Any]] as [String: Any]
            ] as [String: Any]
        ] as [String: Any],
        "enrolled_variants": ["variant_key": "variant_value"]
    ]

}
