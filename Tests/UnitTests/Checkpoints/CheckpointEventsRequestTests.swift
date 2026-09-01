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
        expect(request.appUserID) == Self.userID
        expect(request.appSessionID) == Self.appSessionID.uuidString
        expect(request.timestamp) == self.date.millisecondsSince1970
        expect(request.result) == .workflow
        expect(request.workflowID) == "wf_123"
        expect(request.offeringID) == "offering_id"
    }

    func testKhepriCompatibleShape() throws {
        let json = try self.encodedJSON()

        expect(json).to(contain("\"id\":\"\(self.id.uuidString)\""))
        expect(json).to(contain("\"version\":1"))
        expect(json).to(contain("\"type\":\"checkpoint_hit\""))
        expect(json).to(contain("\"identifier\":\"onboarding_complete\""))
        expect(json).to(contain("\"app_user_id\":\"\(Self.userID)\""))
        expect(json).to(contain("\"app_session_id\":\"\(Self.appSessionID.uuidString)\""))
        expect(json).to(contain("\"timestamp\":\(self.date.millisecondsSince1970)"))
        expect(json).to(contain("\"result\":\"workflow\""))
        expect(json).to(contain("\"workflow_id\":\"wf_123\""))
        expect(json).to(contain("\"offering_id\":\"offering_id\""))
    }

    func testEachResultIsEncodedWithItsWireValue() throws {
        let expectedValues: [CheckpointHitResult: String] = [
            .workflow: "workflow",
            .offering: "offering",
            .noMatch: "no_match",
            .configurationUnavailable: "configuration_unavailable",
            .unknownCheckpoint: "unknown_checkpoint"
        ]

        for (result, expectedValue) in expectedValues {
            let json = try self.encodedJSON(result: result, workflowID: nil, offeringID: nil)

            expect(json).to(contain("\"result\":\"\(expectedValue)\""))
        }
    }

    /// `checkpoint_hit` keeps the shape it had before the outcome was attached when there is no outcome to
    /// report, which is the case for hits already stored by an older SDK version.
    func testOmitsOutcomeFieldsWhenAbsent() throws {
        let json = try self.encodedJSON(result: nil, workflowID: nil, offeringID: nil)

        expect(json).toNot(contain("result"))
        expect(json).toNot(contain("workflow_id"))
        expect(json).toNot(contain("offering_id"))
    }

    /// Events persisted by an SDK version that recorded hits before evaluating them carry none of the outcome
    /// fields, and still have to be readable off disk.
    func testReadsStoredEventWithoutOutcomeFields() throws {
        let stored = try self.storedEvent(result: nil, workflowID: nil, offeringID: nil)

        expect(stored.encodedEvent).toNot(contain("result"))
        expect(stored.encodedEvent).toNot(contain("workflow_id"))
        expect(stored.encodedEvent).toNot(contain("offering_id"))

        let request = try XCTUnwrap(FeatureEventsRequest.CheckpointEvent(storedEvent: stored))

        expect(request.identifier) == "onboarding_complete"
        expect(request.result).to(beNil())
        expect(request.workflowID).to(beNil())
        expect(request.offeringID).to(beNil())
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

    private func storedEvent(
        appSessionID: UUID? = CheckpointEventsRequestTests.appSessionID,
        result: CheckpointHitResult? = .workflow,
        workflowID: String? = "wf_123",
        offeringID: String? = "offering_id"
    ) throws -> StoredFeatureEvent {
        let event = CheckpointEvent.hit(.init(id: self.id,
                                              identifier: "onboarding_complete",
                                              date: self.date,
                                              result: result,
                                              workflowID: workflowID,
                                              offeringID: offeringID))

        return try XCTUnwrap(StoredFeatureEvent(
            event: event,
            userID: Self.userID,
            feature: .checkpoints,
            appSessionID: appSessionID,
            eventDiscriminator: nil
        ))
    }

    private func encodedJSON(
        result: CheckpointHitResult? = .workflow,
        workflowID: String? = "wf_123",
        offeringID: String? = "offering_id"
    ) throws -> String {
        let stored = try self.storedEvent(result: result, workflowID: workflowID, offeringID: offeringID)
        let request = try XCTUnwrap(FeatureEventsRequest.CheckpointEvent(storedEvent: stored))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        return try XCTUnwrap(String(data: encoder.encode(request), encoding: .utf8))
    }

}
