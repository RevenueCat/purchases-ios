//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointEventsRequestTests.swift

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class CheckpointEventsRequestTests: TestCase {

    private static let userID = "app_user_id"
    private static let appSessionID = UUID(uuidString: "315107f4-98bf-4b68-a582-eb27bcb6e111")!

    private let id = UUID(uuidString: "498207f4-87af-4b57-a581-eb27bcc6e009")!
    private let date = Date(timeIntervalSince1970: 1_699_270_688.995)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testWireFormatCarriesExpectedFields() throws {
        let request = try XCTUnwrap(FeatureEventsRequest.CheckpointEvent(storedEvent: try self.storedEvent()))

        expect(request.id) == self.id.uuidString
        expect(request.version) == 1
        expect(request.type) == "checkpoint_hit"
        expect(request.identifier) == "onboarding_complete"
        expect(request.checkpointType) == "custom"
        expect(request.appUserID) == Self.userID
        expect(request.appSessionID) == Self.appSessionID.uuidString
        expect(request.timestamp) == self.date.millisecondsSince1970
        expect(request.result) == "present_ui"
        expect(request.workflowID) == "wf_123"
        expect(request.offeringID) == "offering_id"
        expect(request.checkpointRuleID) == "rule_123"
    }

    func testKhepriCompatibleShape() throws {
        let json = try self.encodedJSON()

        expect(json).to(contain("\"id\":\"\(self.id.uuidString)\""))
        expect(json).to(contain("\"version\":1"))
        expect(json).to(contain("\"type\":\"checkpoint_hit\""))
        expect(json).to(contain("\"identifier\":\"onboarding_complete\""))
        expect(json).to(contain("\"checkpoint_type\":\"custom\""))
        expect(json).to(contain("\"app_user_id\":\"\(Self.userID)\""))
        expect(json).to(contain("\"app_session_id\":\"\(Self.appSessionID.uuidString)\""))
        expect(json).to(contain("\"timestamp\":\(self.date.millisecondsSince1970)"))
        expect(json).to(contain("\"result\":\"present_ui\""))
        expect(json).to(contain("\"workflow_id\":\"wf_123\""))
        expect(json).to(contain("\"offering_id\":\"offering_id\""))
        expect(json).to(contain("\"checkpoint_rule_id\":\"rule_123\""))
    }

    func testEachResultIsEncodedWithItsWireValue() throws {
        let expected: [CheckpointHitResult: String] = [
            .presentUI: "present_ui",
            .returnData: "return_data",
            .noMatch: "no_match",
            .configurationUnavailable: "configuration_unavailable",
            .unknownCheckpoint: "unknown_checkpoint"
        ]

        for (result, wireValue) in expected {
            let json = try self.encodedJSON(data: .init(id: self.id,
                                                        identifier: "onboarding_complete",
                                                        date: self.date,
                                                        checkpointType: .custom,
                                                        result: result))

            expect(json).to(contain("\"result\":\"\(wireValue)\""))
        }
    }

    /// The ids go through the store's `convertToSnakeCase` on the way out and `convertFromSnakeCase` on the
    /// way back, which turns `workflow_id` into `workflowId`. Without explicit coding keys they decode as nil
    /// and the hit reaches the backend with no outcome attached.
    func testOutcomeIdsSurviveTheStoreRoundTrip() throws {
        let request = try XCTUnwrap(FeatureEventsRequest.CheckpointEvent(storedEvent: try self.storedEvent()))

        expect(request.workflowID) == "wf_123"
        expect(request.offeringID) == "offering_id"
        expect(request.checkpointRuleID) == "rule_123"
    }

    /// A hit stored by an SDK version that recorded it before resolving carries no outcome, and still has to
    /// reach the backend: the hit is how the checkpoint gets registered.
    func testReadsStoredEventWithoutOutcomeFields() throws {
        let stored = try self.storedEvent(data: .init(id: self.id,
                                                      identifier: "onboarding_complete",
                                                      date: self.date))
        let request = try XCTUnwrap(FeatureEventsRequest.CheckpointEvent(storedEvent: stored))

        expect(request.identifier) == "onboarding_complete"
        expect(request.checkpointType).to(beNil())
        expect(request.result).to(beNil())
    }

    /// `checkpoint_hit` keeps the shape it had before the outcome was attached when there is none to report.
    func testOmitsOutcomeFieldsWhenAbsent() throws {
        let json = try self.encodedJSON(data: .init(id: self.id,
                                                    identifier: "onboarding_complete",
                                                    date: self.date))

        expect(json).toNot(contain("checkpoint_type"))
        expect(json).toNot(contain("result"))
        expect(json).toNot(contain("workflow_id"))
        expect(json).toNot(contain("offering_id"))
        expect(json).toNot(contain("checkpoint_rule_id"))
    }

    /// khepri discriminates the events union on `type`, so nothing downstream reads a `discriminator` key.
    func testDiscriminatorAbsentFromJSON() throws {
        let json = try self.encodedJSON()

        expect(json).toNot(contain("discriminator"))
    }

    func testReturnsNilWhenAppSessionIDIsMissing() throws {
        let stored = try self.storedEvent(appSessionID: nil)

        expect(FeatureEventsRequest.CheckpointEvent(storedEvent: stored)).to(beNil())
    }

    func testReturnsNilForNonCheckpointStoredEvent() throws {
        let event = CheckpointEvent.hit(.init(id: self.id, identifier: "onboarding_complete", date: self.date))
        let stored = try XCTUnwrap(StoredFeatureEvent(
            event: event,
            userID: Self.userID,
            feature: .paywalls,
            appSessionID: Self.appSessionID,
            eventDiscriminator: nil
        ))

        expect(FeatureEventsRequest.CheckpointEvent(storedEvent: stored)).to(beNil())
    }

    // MARK: - Helpers

    private var resolvedData: CheckpointEvent.Data {
        .init(id: self.id,
              identifier: "onboarding_complete",
              date: self.date,
              checkpointType: .custom,
              result: .presentUI,
              workflowID: "wf_123",
              offeringID: "offering_id",
              checkpointRuleID: "rule_123")
    }

    private func storedEvent(appSessionID: UUID? = CheckpointEventsRequestTests.appSessionID,
                             data: CheckpointEvent.Data? = nil) throws
    -> StoredFeatureEvent {
        let event = CheckpointEvent.hit(data ?? self.resolvedData)

        return try XCTUnwrap(StoredFeatureEvent(
            event: event,
            userID: Self.userID,
            feature: .checkpoints,
            appSessionID: appSessionID,
            eventDiscriminator: nil
        ))
    }

    private func encodedJSON(data: CheckpointEvent.Data? = nil) throws -> String {
        let stored = try self.storedEvent(data: data)
        let request = try XCTUnwrap(FeatureEventsRequest.CheckpointEvent(storedEvent: stored))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        return try XCTUnwrap(String(data: encoder.encode(request), encoding: .utf8))
    }

}
