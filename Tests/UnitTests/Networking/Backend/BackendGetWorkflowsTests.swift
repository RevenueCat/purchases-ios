//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendGetWorkflowsTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendGetWorkflowsTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetWorkflowsCallsHTTPMethod() {
        self.httpClient.mock(
            requestPath: .getWorkflows(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.emptyWorkflowsResponse)
        )

        let result = waitUntilValue { completed in
            self.workflowsAPI.getWorkflows(
                appUserID: Self.userID,
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
    }

    func testGetWorkflowsCallsHTTPMethodWithRandomDelayWhenBackgrounded() {
        self.httpClient.mock(
            requestPath: .getWorkflows(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.emptyWorkflowsResponse)
        )

        let result = waitUntilValue { completed in
            self.workflowsAPI.getWorkflows(
                appUserID: Self.userID,
                isAppBackgrounded: true,
                completion: completed
            )
        }

        expect(result).to(beSuccess())
        expect(self.httpClient.calls).to(haveCount(1))
        expect(self.operationDispatcher.invokedDispatchOnWorkerThreadDelayParam) == .default
    }

    func testGetWorkflowsCachesForSameUserID() {
        self.httpClient.mock(
            requestPath: .getWorkflows(appUserID: Self.userID),
            response: .init(statusCode: .success,
                            response: Self.emptyWorkflowsResponse,
                            delay: .milliseconds(10))
        )
        self.workflowsAPI.getWorkflows(appUserID: Self.userID, isAppBackgrounded: false) { _ in }
        self.workflowsAPI.getWorkflows(appUserID: Self.userID, isAppBackgrounded: false) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetWorkflowsReturnsWorkflows() throws {
        self.httpClient.mock(
            requestPath: .getWorkflows(appUserID: Self.userID),
            response: .init(statusCode: .success, response: Self.oneWorkflowResponse)
        )

        let result: Atomic<Result<WorkflowsListResponse, BackendError>?> = nil
        self.workflowsAPI.getWorkflows(appUserID: Self.userID, isAppBackgrounded: false) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil())

        let response = try XCTUnwrap(result.value?.value)
        expect(response.workflows).to(haveCount(1))
        expect(response.workflows.first?.id) == "wf_1"
        expect(response.workflows.first?.displayName) == "Flow A"
    }

    func testGetWorkflowsNetworkErrorSendsError() {
        let mockedError: NetworkError = .unexpectedResponse(nil)

        self.httpClient.mock(
            requestPath: .getWorkflows(appUserID: Self.userID),
            response: .init(error: mockedError)
        )

        let result = waitUntilValue { completed in
            self.workflowsAPI.getWorkflows(
                appUserID: Self.userID,
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beFailure())
        expect(result?.error) == .networkError(mockedError)
    }

    func testGetWorkflowsSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.workflowsAPI.getWorkflows(appUserID: "", isAppBackgrounded: false) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

    func testGetWorkflowsCallsCompletionWithErrorIfAppUserIDIsEmpty() {
        let receivedError = waitUntilValue { completed in
            self.workflowsAPI.getWorkflows(appUserID: "", isAppBackgrounded: false) { result in
                completed(result.error)
            }
        }

        expect(receivedError) == .missingAppUserID()
    }

}

// MARK: - GetWorkflow tests

class BackendGetWorkflowTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetWorkflowInlineUnwrapsData() throws {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowId: "wf_1"),
            response: .init(statusCode: .success, response: Self.inlineEnvelopeResponse)
        )

        let result: Atomic<Result<WorkflowFetchResult, BackendError>?> = nil
        self.workflowsAPI.getWorkflow(
            appUserID: Self.userID,
            workflowId: "wf_1",
            isAppBackgrounded: false
        ) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil())

        let fetchResult = try XCTUnwrap(result.value?.value)
        expect(fetchResult.workflow.id) == "wf_1"
        expect(fetchResult.workflow.displayName) == "Test Workflow"
        expect(fetchResult.workflow.initialStepId) == "step_1"
        expect(fetchResult.enrolledVariants).to(beNil())
    }

    func testGetWorkflowInlineWithEnrolledVariants() throws {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowId: "wf_1"),
            response: .init(statusCode: .success, response: Self.inlineEnvelopeWithVariantsResponse)
        )

        let result: Atomic<Result<WorkflowFetchResult, BackendError>?> = nil
        self.workflowsAPI.getWorkflow(
            appUserID: Self.userID,
            workflowId: "wf_1",
            isAppBackgrounded: false
        ) {
            result.value = $0
        }

        expect(result.value).toEventuallyNot(beNil())

        let fetchResult = try XCTUnwrap(result.value?.value)
        expect(fetchResult.workflow.id) == "wf_1"
        expect(fetchResult.enrolledVariants) == ["experiment_1": "variant_a"]
    }

    func testGetWorkflowPropagatesHTTPErrors() {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowId: "wf_missing"),
            response: .init(statusCode: .notFoundError, response: ["error": "not found"] as [String: Any])
        )

        let result = waitUntilValue { completed in
            self.workflowsAPI.getWorkflow(
                appUserID: Self.userID,
                workflowId: "wf_missing",
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beFailure())
    }

    func testGetWorkflowCachesForSameUserIDAndWorkflowId() {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowId: "wf_1"),
            response: .init(statusCode: .success,
                            response: Self.inlineEnvelopeResponse,
                            delay: .milliseconds(10))
        )

        self.workflowsAPI.getWorkflow(
            appUserID: Self.userID,
            workflowId: "wf_1",
            isAppBackgrounded: false
        ) { _ in }
        self.workflowsAPI.getWorkflow(
            appUserID: Self.userID,
            workflowId: "wf_1",
            isAppBackgrounded: false
        ) { _ in }

        expect(self.httpClient.calls).toEventually(haveCount(1))
    }

    func testGetWorkflowUseCdnFetchesWorkflowFromCdnUrl() throws {
        let cdnWorkflowData = try JSONSerialization.data(withJSONObject: Self.minimalWorkflowData)
        self.stubbedCdnFetch = { _, completion in completion(.success(cdnWorkflowData)) }

        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowId: "wf_1"),
            response: .init(statusCode: .success, response: Self.cdnEnvelopeResponse)
        )

        let result = waitUntilValue { completed in
            self.workflowsAPI.getWorkflow(
                appUserID: Self.userID,
                workflowId: "wf_1",
                isAppBackgrounded: false,
                completion: completed
            )
        }

        expect(result).to(beSuccess { fetchResult in
            expect(fetchResult.workflow.id) == "wf_1"
            expect(fetchResult.workflow.displayName) == "Test Workflow"
        })
    }

    func testGetWorkflowSkipsBackendCallIfAppUserIDIsEmpty() {
        waitUntil { completed in
            self.workflowsAPI.getWorkflow(
                appUserID: "",
                workflowId: "wf_1",
                isAppBackgrounded: false
            ) { _ in
                completed()
            }
        }

        expect(self.httpClient.calls).to(beEmpty())
    }

}

// MARK: - Test data

private extension BackendGetWorkflowsTests {

    static let minimalUiConfig: [String: Any] = [
        "app": [
            "colors": [:] as [String: Any],
            "fonts": [:] as [String: Any]
        ] as [String: Any],
        "localizations": [:] as [String: Any],
        "variable_config": [
            "variable_compatibility_map": [:] as [String: String],
            "function_compatibility_map": [:] as [String: String]
        ] as [String: Any]
    ]

    static let emptyWorkflowsResponse: [String: Any] = [
        "workflows": [] as [Any],
        "ui_config": minimalUiConfig
    ]

    static let oneWorkflowResponse: [String: Any] = [
        "workflows": [
            [
                "id": "wf_1",
                "display_name": "Flow A"
            ] as [String: Any]
        ],
        "ui_config": minimalUiConfig
    ]

}

private extension BackendGetWorkflowTests {

    static let minimalUiConfig: [String: Any] = [
        "app": [
            "colors": [:] as [String: Any],
            "fonts": [:] as [String: Any]
        ] as [String: Any],
        "localizations": [:] as [String: Any],
        "variable_config": [
            "variable_compatibility_map": [:] as [String: String],
            "function_compatibility_map": [:] as [String: String]
        ] as [String: Any]
    ]

    static let minimalWorkflowData: [String: Any] = [
        "id": "wf_1",
        "display_name": "Test Workflow",
        "initial_step_id": "step_1",
        "steps": [
            "step_1": [
                "id": "step_1",
                "type": "screen"
            ] as [String: Any]
        ] as [String: Any],
        "screens": [:] as [String: Any],
        "ui_config": minimalUiConfig
    ]

    static let inlineEnvelopeResponse: [String: Any] = [
        "action": "inline",
        "data": minimalWorkflowData
    ]

    static let inlineEnvelopeWithVariantsResponse: [String: Any] = [
        "action": "inline",
        "data": minimalWorkflowData,
        "enrolled_variants": [
            "experiment_1": "variant_a"
        ] as [String: String]
    ]

    static let cdnEnvelopeResponse: [String: Any] = [
        "action": "use_cdn",
        "url": "https://cdn.example/wf.json"
    ]

}
