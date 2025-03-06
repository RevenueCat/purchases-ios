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

    func testPostDiagnosticsEventsWithOneEvent() {
        let event = DiagnosticsEvent(name: .customerInfoVerificationResult,
                                     properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                     timestamp: Self.eventTimestamp1)

        let error = waitUntilValue { completion in
            self.internalAPI.postDiagnosticsEvents(events: [event], completion: completion)
        }

        expect(error).to(beNil())
    }

    func testPostDiagnosticsEventsWithMultipleEvents() {
        let event1 = DiagnosticsEvent(name: .customerInfoVerificationResult,
                                      properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                      timestamp: Self.eventTimestamp1)

        let event2 = DiagnosticsEvent(name: .customerInfoVerificationResult,
                                      properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                      timestamp: Self.eventTimestamp2)

        let error = waitUntilValue { completion in
            self.internalAPI.postDiagnosticsEvents(events: [event1, event2], completion: completion)
        }

        expect(error).to(beNil())
    }

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension BackendPostDiagnosticsTests {

    static let eventTimestamp1: Date = .init(timeIntervalSince1970: 1694029328)
    static let eventTimestamp2: Date = .init(timeIntervalSince1970: 1694022321)

}
