//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentInteractionLoggerTests.swift
//
//  Created by RevenueCat on 4/6/26.
//

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
@MainActor
class ComponentInteractionLoggerTests: TestCase {

    func testTracking() async throws {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])

        let tracker = PaywallEventTracker(
            purchases: MockPurchases(
                purchase: { _, _, _ in
                    (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
                },
                restorePurchases: { TestData.customerInfo },
                trackEvent: { event in
                    trackedEvents.modify { $0.append(event) }
                },
                customerInfo: { TestData.customerInfo }
            ),
            eventDispatcher: PaywallEventTrackerTestDispatcher.value
        )

        let eventData: PaywallEvent.Data = .init(
            offering: TestData.offeringWithIntroOffer,
            paywall: TestData.paywallWithIntroOffer,
            sessionID: .init(),
            displayMode: .fullScreen,
            locale: .init(identifier: "en_US"),
            darkMode: false,
            source: nil
        )

        let interactionData = PaywallEvent.ComponentInteractionData(
            componentType: .text,
            componentName: "link_copy",
            componentValue: "navigate_to_url",
            componentURL: URL(string: "https://example.com/docs")
        )

        let logger = tracker.componentInteractionLogger(sessionID: eventData.sessionIdentifier)

        expect(logger(interactionData)) == false

        tracker.trackPaywallImpression(eventData)

        expect(logger(interactionData)) == true

        await Task(priority: .low) {
            await Task.yield()
        }.value

        let interactionEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .componentInteraction = $0 { return true }
            return false
        }))

        guard case let .componentInteraction(_, data, interaction) = interactionEvent else {
            fail("Expected componentInteraction event")
            return
        }

        expect(data.sessionIdentifier) == eventData.sessionIdentifier
        expect(interaction.componentType) == .text
        expect(interaction.componentName) == "link_copy"
        expect(interaction.componentValue) == "navigate_to_url"
        expect(interaction.componentURL) == URL(string: "https://example.com/docs")
    }

}
