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
    }

    /// khepri discriminates the events union on `type`, so nothing downstream reads a `discriminator` key.
    func testDiscriminatorAbsentFromJSON() throws {
        let json = try self.encodedJSON()

        expect(json).toNot(contain("discriminator"))
    }

    func testAppSessionIDAbsentFromJSONWhenMissing() throws {
        let json = try self.encodedJSON(appSessionID: nil)

        expect(json).toNot(contain("app_session_id"))
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

    private func storedEvent(appSessionID: UUID? = CheckpointEventsRequestTests.appSessionID) throws
    -> StoredFeatureEvent {
        let event = CheckpointEvent.hit(.init(id: self.id, identifier: "onboarding_complete", date: self.date))

        return try XCTUnwrap(StoredFeatureEvent(
            event: event,
            userID: Self.userID,
            feature: .checkpoints,
            appSessionID: appSessionID,
            eventDiscriminator: nil
        ))
    }

    private func encodedJSON(appSessionID: UUID? = CheckpointEventsRequestTests.appSessionID) throws -> String {
        let stored = try self.storedEvent(appSessionID: appSessionID)
        let request = try XCTUnwrap(FeatureEventsRequest.CheckpointEvent(storedEvent: stored))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        return try XCTUnwrap(String(data: encoder.encode(request), encoding: .utf8))
    }

}
