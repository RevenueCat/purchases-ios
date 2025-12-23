//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostDiagnosticsTests.swift
//
//  Created by Cesar de la Vega on 10/4/24.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class BackendPostDiagnosticsTests: BaseBackendTests {

    static let eventId1 = UUID(uuidString: "8FDEAD13-A05B-4236-84CF-36BCDD36A7BC")!
    static let eventId2 = UUID(uuidString: "4FAF3FE9-F239-4CC1-BB07-C3320BA40BCF")!

    static let appSessionId = UUID(uuidString: "FD06888D-DEA6-43C5-A36A-A1E06F2D6A42")!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostDiagnosticsEventsWithNoEventsMakesNoRequests() {
        let error = waitUntilValue { completion in
            self.internalAPI.postDiagnosticsEvents(events: [], completion: completion)
        }

        expect(error).to(beNil())
        expect(self.httpClient.calls).to(beEmpty())
    }

    func testPostDiagnosticsEventsWithOneEvent() async {
        let event = DiagnosticsEvent(id: Self.eventId1,
                                     name: .customerInfoVerificationResult,
                                     properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                     timestamp: Self.eventTimestamp1,
                                     appSessionId: Self.appSessionId)

        await expect {
            try await self.internalAPI.postDiagnosticsEvents(events: [event])
        }.toNot(throwError())
    }

    func testPostDiagnosticsEventsWithMultipleEvents() async {
        let event1 = DiagnosticsEvent(id: Self.eventId1,
                                      name: .customerInfoVerificationResult,
                                      properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                      timestamp: Self.eventTimestamp1,
                                      appSessionId: Self.appSessionId)

        let event2 = DiagnosticsEvent(id: Self.eventId2,
                                      name: .customerInfoVerificationResult,
                                      properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                      timestamp: Self.eventTimestamp2,
                                      appSessionId: Self.appSessionId)

        await expect {
            try await self.internalAPI.postDiagnosticsEvents(events: [event1, event2])
        }.toNot(throwError())
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BackendPostDiagnosticsTests {

    static let eventTimestamp1: Date = .init(timeIntervalSince1970: 1694029328)
    static let eventTimestamp2: Date = .init(timeIntervalSince1970: 1694022321)

}
