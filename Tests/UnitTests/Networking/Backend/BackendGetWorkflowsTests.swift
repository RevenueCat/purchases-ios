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

@_spi(Internal) @testable import RevenueCat

class BackendGetWorkflowTests: BaseBackendTests {

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testGetWorkflowInlineUnwrapsData() throws {
        self.httpClient.mock(
            requestPath: .getWorkflow(appUserID: Self.userID, workflowId: "wf_1"),
            response: .init(statusCode: .success, response: Self.inlineEnvelopeResponse)
        )

        let result: Atomic<Result<WorkflowDataResult, BackendError>?> = nil
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

        let result: Atomic<Result<WorkflowDataResult, BackendError>?> = nil
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
        self.stubbedCdnFetch = { _, _, completion in completion(.success(cdnWorkflowData)) }

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
