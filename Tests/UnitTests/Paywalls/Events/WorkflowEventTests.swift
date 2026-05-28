//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowEventTests.swift

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class WorkflowEventTests: TestCase {

    private let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let date = Date(timeIntervalSince1970: 1_717_000_000)

    // MARK: - StepStarted

    func testStepStartedCarriesRequiredFields() {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1")
        )

        expect(event.creationData.id) == id
        expect(event.creationData.date) == date
        expect(event.data.workflowId) == "wfl_abc"
        expect(event.data.stepId) == "step-1"
    }

    func testStepStartedOptionalFieldsAreNilByDefault() {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1")
        )

        expect(event.data.workflowType).to(beNil())
        expect(event.data.stepType).to(beNil())
        expect(event.data.screenType).to(beEmpty())
        expect(event.data.traceId).to(beNil())
        expect(event.data.fromStepId).to(beNil())
        expect(event.data.toStepId).to(beNil())
        expect(event.data.entryReason).to(beNil())
        expect(event.data.isFirstStep).to(beNil())
        expect(event.data.isLastStep).to(beNil())
        expect(event.data.experimentId).to(beNil())
        expect(event.data.experimentVariant).to(beNil())
        expect(event.data.isLastVariantStep).to(beNil())
    }

    func testStepStartedOptionalFieldsCanBeSet() {
        let event = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(
                workflowId: "wfl_abc",
                stepId: "step-1",
                workflowType: "paywall",
                stepType: "screen",
                screenType: ["screen_type_a"],
                fromStepId: "step-0",
                entryReason: "start",
                isFirstStep: true,
                isLastStep: false
            )
        )

        expect(event.data.workflowType) == "paywall"
        expect(event.data.stepType) == "screen"
        expect(event.data.screenType) == ["screen_type_a"]
        expect(event.data.fromStepId) == "step-0"
        expect(event.data.entryReason) == "start"
        expect(event.data.isFirstStep) == true
        expect(event.data.isLastStep) == false
    }

    // MARK: - StepCompleted

    func testStepCompletedCarriesRequiredFields() {
        let event = WorkflowEvent.stepCompleted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1")
        )

        expect(event.creationData.id) == id
        expect(event.creationData.date) == date
        expect(event.data.workflowId) == "wfl_abc"
        expect(event.data.stepId) == "step-1"
    }

    func testStepCompletedCarriesToStepId() {
        let withNext = WorkflowEvent.stepCompleted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", toStepId: "step-2")
        )
        let terminal = WorkflowEvent.stepCompleted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", toStepId: nil)
        )

        expect(withNext.data.toStepId) == "step-2"
        expect(terminal.data.toStepId).to(beNil())
    }

    // MARK: - FeatureEvent conformance

    func testFeatureIsWorkflows() {
        let started = WorkflowEvent.stepStarted(.init(id: id, date: date), .init(workflowId: "w", stepId: "s"))
        let completed = WorkflowEvent.stepCompleted(.init(id: id, date: date), .init(workflowId: "w", stepId: "s"))

        expect(started.feature) == .workflows
        expect(completed.feature) == .workflows
    }

    func testIsNotPriorityEvent() {
        let started = WorkflowEvent.stepStarted(.init(id: id, date: date), .init(workflowId: "w", stepId: "s"))
        let completed = WorkflowEvent.stepCompleted(.init(id: id, date: date), .init(workflowId: "w", stepId: "s"))

        expect(started.isPriorityEvent) == false
        expect(completed.isPriorityEvent) == false
    }

    func testShouldStoreEvent() {
        let started = WorkflowEvent.stepStarted(.init(id: id, date: date), .init(workflowId: "w", stepId: "s"))
        let completed = WorkflowEvent.stepCompleted(.init(id: id, date: date), .init(workflowId: "w", stepId: "s"))

        expect(started.shouldStoreEvent) == true
        expect(completed.shouldStoreEvent) == true
    }

}

// MARK: - Codable round-trip (via StoredFeatureEvent)

extension WorkflowEventTests {

    func testStepStartedRoundTrips() throws {
        let original = WorkflowEvent.stepStarted(
            .init(id: id, date: date),
            .init(
                workflowId: "wfl_abc",
                stepId: "step-1",
                workflowType: "paywall",
                stepType: "screen",
                screenType: ["type_a"],
                fromStepId: "step-0",
                entryReason: "start",
                isFirstStep: true,
                isLastStep: false
            )
        )

        let stored = try XCTUnwrap(StoredFeatureEvent(
            event: original,
            userID: "user",
            feature: .workflows,
            appSessionID: nil,
            eventDiscriminator: nil
        ))
        let jsonData = try XCTUnwrap(stored.encodedEvent.data(using: .utf8))
        let decoded = try JSONDecoder.default.decode(WorkflowEvent.self, from: jsonData)

        expect(decoded.creationData.id) == original.creationData.id
        expect(decoded.data.workflowId) == original.data.workflowId
        expect(decoded.data.stepId) == original.data.stepId
        expect(decoded.data.workflowType) == original.data.workflowType
        expect(decoded.data.stepType) == original.data.stepType
        expect(decoded.data.screenType) == original.data.screenType
        expect(decoded.data.fromStepId) == original.data.fromStepId
        expect(decoded.data.entryReason) == original.data.entryReason
        expect(decoded.data.isFirstStep) == original.data.isFirstStep
        expect(decoded.data.isLastStep) == original.data.isLastStep
    }

    func testStepCompletedRoundTrips() throws {
        let original = WorkflowEvent.stepCompleted(
            .init(id: id, date: date),
            .init(workflowId: "wfl_abc", stepId: "step-1", toStepId: "step-2", isFirstStep: true, isLastStep: false)
        )

        let stored = try XCTUnwrap(StoredFeatureEvent(
            event: original,
            userID: "user",
            feature: .workflows,
            appSessionID: nil,
            eventDiscriminator: nil
        ))
        let jsonData = try XCTUnwrap(stored.encodedEvent.data(using: .utf8))
        let decoded = try JSONDecoder.default.decode(WorkflowEvent.self, from: jsonData)

        expect(decoded.data.toStepId) == "step-2"
        expect(decoded.data.isFirstStep) == true
        expect(decoded.data.isLastStep) == false
    }

}

// MARK: - Helpers

private extension WorkflowEvent {

    var creationData: WorkflowEvent.CreationData {
        switch self {
        case let .stepStarted(creationData, _): return creationData
        case let .stepCompleted(creationData, _): return creationData
        }
    }

    var data: WorkflowEvent.Data {
        switch self {
        case let .stepStarted(_, data): return data
        case let .stepCompleted(_, data): return data
        }
    }

}
