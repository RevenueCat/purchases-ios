//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsManagerIntegrationTests.swift
//
//  Created by Facundo Menzella on 26/2/25.

import Nimble
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

@MainActor
final class EventsManagerIntegrationTests: BaseBackendIntegrationTests {

    override var apiKey: String { return Constants.customEntitlementComputationApiKey }

    var eventsManager: PaywallEventsManager!

    func testPostingPaywallsDoesNotFail() async throws {
        let events = [
            PaywallEvent.cancel(
                Self.eventCreationData, Self.eventData
            ),
            PaywallEvent.close(
                Self.eventCreationData, Self.eventData
            ),
            PaywallEvent.impression(
                Self.eventCreationData, Self.eventData
            )
        ]

        for event in events {
            await eventsManager.track(
                featureEvent: event
            )
        }

        _ = try await eventsManager.flushEvents(count: 100)

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.event_flush_starting(count: events.count)
        )

        try self.logger.verifyMessageWasLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            expectedCount: 1
        )
    }

    func testPostingCustomerCenterDoesNotFail() async throws {
        let locale = Locale(identifier: "es_ES")
        await eventsManager.track(
            featureEvent: CustomerCenterEvent.impression(
                Self.customerCenterCreationData,
                CustomerCenterEvent.Data(
                    locale: locale,
                    darkMode: true,
                    isSandbox: true,
                    displayMode: .fullScreen
                )
            )
        )

        await eventsManager.track(
            featureEvent: CustomerCenterAnswerSubmittedEvent.answerSubmitted(
                Self.customerCenterCreationData,
                CustomerCenterAnswerSubmittedEvent.Data(
                    locale: locale,
                    darkMode: true,
                    isSandbox: true,
                    displayMode: .fullScreen,
                    path: .cancel,
                    url: nil,
                    surveyOptionID: "",
                    revisionID: 1
                )
            )
        )

        _ = try await eventsManager.flushEvents(count: 2)

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.event_flush_starting(count: 2)
        )

        self.logger.verifyMessageWasLogged(
            Strings.analytics.flush_events_success,
            level: .debug,
            expectedCount: 1
        )
    }

    static let customerCenterCreationData: CustomerCenterEventCreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventCreationData: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventData: PaywallEvent.Data = .init(
        offeringIdentifier: "offering",
        paywallRevision: 0,
        sessionID: .init(uuidString: "98CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .fullScreen,
        localeIdentifier: "es_ES",
        darkMode: true
    )
}
