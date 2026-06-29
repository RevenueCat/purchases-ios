//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowEventsRequestTests.swift

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class WorkflowEventsRequestTests: TestCase {

    private let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let date = Date(timeIntervalSince1970: 1_717_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    // MARK: - StepStarted wire format

    func testStepStartedEventNameInWireFormat() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", entryReason: "start", isFirstStep: true, isLastStep: false)
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.eventName) == "workflow_step_started"
    }

    func testStepCompletedEventNameInWireFormat() throws {
        let event = WorkflowEvent.stepCompleted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", toStepId: "step-2")
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.eventName) == "workflow_step_completed"
    }

    func testWireFormatCarriesExpectedFields() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(
                workflowId: "wfl_abc",
                stepId: "step-1",
                fromStepId: "step-0",
                entryReason: "start",
                isFirstStep: true,
                isLastStep: false
            )
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.id) == id.uuidString
        expect(request.version) == 1
        expect(request.appUserID) == Self.userID
        expect(request.timestampMs) == date.millisecondsSince1970
        expect(request.properties.workflowId) == "wfl_abc"
        expect(request.properties.stepId) == "step-1"
        expect(request.properties.fromStepId) == "step-0"
        expect(request.properties.entryReason) == "start"
        expect(request.properties.isFirstStep) == true
        expect(request.properties.isLastStep) == false
        expect(request.properties.toStepId).to(beNil())
    }

    func testLocaleIsPopulatedInContext() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", localeIdentifier: "en_US")
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.context.locale) == "en_US"
    }

    func testLocaleIsIncludedInJSON() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", localeIdentifier: "fr_FR")
        )
        let json = try encodedJSON(from: event)

        expect(json).to(contain("\"locale\":\"fr_FR\""))
    }

    func testStepCompletedPropertiesIncludeToStepId() throws {
        let event = WorkflowEvent.stepCompleted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", toStepId: "step-2", isFirstStep: false, isLastStep: true)
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.properties.toStepId) == "step-2"
        expect(request.properties.isFirstStep) == false
        expect(request.properties.isLastStep) == true
        expect(request.properties.fromStepId).to(beNil())
        expect(request.properties.entryReason).to(beNil())
    }

    // MARK: - Close wire format

    func testCloseEventNameInWireFormat() throws {
        let event = WorkflowEvent.close(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", isFirstStep: true, isLastStep: false)
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.eventName) == "workflow_close"
    }

    func testClosePropertiesCarryStepPositionAndOmitNavigationFields() throws {
        let event = WorkflowEvent.close(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", isFirstStep: false, isLastStep: true)
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.properties.workflowId) == "wfl_abc"
        expect(request.properties.stepId) == "step-1"
        expect(request.properties.isFirstStep) == false
        expect(request.properties.isLastStep) == true
        // Close is not a navigation event: it has no from/to step and no entry reason.
        expect(request.properties.fromStepId).to(beNil())
        expect(request.properties.toStepId).to(beNil())
        expect(request.properties.entryReason).to(beNil())
    }

    func testKhepriCompatibleShapeForClose() throws {
        let event = WorkflowEvent.close(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", isFirstStep: true, isLastStep: false)
        )
        let json = try encodedJSON(from: event)

        expect(json).to(contain("\"event_name\":\"workflow_close\""))
        expect(json).to(contain("\"workflow_id\":\"wfl_abc\""))
        expect(json).to(contain("\"step_id\":\"step-1\""))
        expect(json).to(contain("\"is_first_step\":true"))
        expect(json).to(contain("\"is_last_step\":false"))
        expect(json).toNot(contain("from_step_id"))
        expect(json).toNot(contain("to_step_id"))
        expect(json).toNot(contain("entry_reason"))
    }

    // MARK: - JSON serialization

    func testTypePresentInJSON() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1")
        )
        let json = try encodedJSON(from: event)

        expect(json).to(contain("\"type\":\"workflows\""))
    }

    func testWorkflowTypeAbsentFromJSON() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", workflowType: "paywall")
        )
        let json = try encodedJSON(from: event)

        expect(json).toNot(contain("workflow_type"))
    }

    func testStepTypeAbsentFromJSON() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", stepType: "screen")
        )
        let json = try encodedJSON(from: event)

        expect(json).toNot(contain("step_type"))
    }

    func testScreenTypeAbsentFromJSON() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", screenType: ["type_a"])
        )
        let json = try encodedJSON(from: event)

        expect(json).toNot(contain("screen_type"))
    }

    func testNullPropertiesAbsentFromJSON() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1")
        )
        let json = try encodedJSON(from: event)

        expect(json).toNot(contain("trace_id"))
        expect(json).toNot(contain("from_step_id"))
        expect(json).toNot(contain("to_step_id"))
        expect(json).toNot(contain("entry_reason"))
        expect(json).toNot(contain("is_first_step"))
        expect(json).toNot(contain("is_last_step"))
        expect(json).toNot(contain("experiment_id"))
        expect(json).toNot(contain("experiment_variant"))
        expect(json).toNot(contain("is_last_variant_step"))
    }

    func testExperimentPropertiesInWireFormat() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(
                workflowId: "wfl_abc",
                stepId: "step-1",
                experimentId: "exp-1",
                experimentVariant: "variant-a",
                isLastVariantStep: true
            )
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))

        expect(request.properties.experimentId) == "exp-1"
        expect(request.properties.experimentVariant) == "variant-a"
        expect(request.properties.isLastVariantStep) == true
    }

    func testExperimentPropertiesInJSON() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(
                workflowId: "wfl_abc",
                stepId: "step-1",
                experimentId: "exp-1",
                experimentVariant: "variant-a",
                isLastVariantStep: false
            )
        )
        let json = try encodedJSON(from: event)

        expect(json).to(contain("\"experiment_id\":\"exp-1\""))
        expect(json).to(contain("\"experiment_variant\":\"variant-a\""))
        expect(json).to(contain("\"is_last_variant_step\":false"))
    }

    func testKhepriCompatibleShapeForStepStarted() throws {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(
                workflowId: "wfl_abc",
                stepId: "step-1",
                entryReason: "start",
                isFirstStep: true,
                isLastStep: false
            )
        )
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try String(data: encoder.encode(request), encoding: .utf8)!

        expect(json).to(contain("\"type\":\"workflows\""))
        expect(json).to(contain("\"version\":1"))
        expect(json).to(contain("\"event_name\":\"workflow_step_started\""))
        expect(json).to(contain("\"timestamp_ms\":\(date.millisecondsSince1970)"))
        expect(json).to(contain("\"app_user_id\":\"\(Self.userID)\""))
        expect(json).to(contain("\"workflow_id\":\"wfl_abc\""))
        expect(json).to(contain("\"step_id\":\"step-1\""))
        expect(json).to(contain("\"entry_reason\":\"start\""))
        expect(json).to(contain("\"is_first_step\":true"))
        expect(json).to(contain("\"is_last_step\":false"))
    }

    // MARK: - Failure cases

    func testReturnsNilForNonWorkflowStoredEvent() throws {
        let paywallEvent = PaywallEvent.impression(
            .init(id: id, date: date),
            .init(
                paywallIdentifier: nil,
                offeringIdentifier: "offering",
                paywallRevision: 1,
                sessionID: UUID(),
                displayMode: .fullScreen,
                localeIdentifier: "en_US",
                darkMode: false
            )
        )
        let stored = try XCTUnwrap(StoredFeatureEvent(
            event: paywallEvent,
            userID: Self.userID,
            feature: .paywalls,
            appSessionID: nil,
            eventDiscriminator: nil
        ))
        let result = FeatureEventsRequest.WorkflowEvent(storedEvent: stored)

        expect(result).to(beNil())
    }

    // MARK: - Helpers

    static let userID = "test_user"

    private func storedEvent(from event: WorkflowEvent) throws -> StoredFeatureEvent? {
        return .init(
            event: event,
            userID: Self.userID,
            feature: .workflows,
            appSessionID: nil,
            eventDiscriminator: nil
        )
    }

    private func encodedJSON(from event: WorkflowEvent) throws -> String {
        let stored = try XCTUnwrap(storedEvent(from: event))
        let request = try XCTUnwrap(FeatureEventsRequest.WorkflowEvent(storedEvent: stored))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try String(data: encoder.encode(request), encoding: .utf8)!
    }

}
