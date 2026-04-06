//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventTrackerTests.swift
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
class PaywallEventTrackerTests: TestCase {

    func testTrackPaywallCloseDeduplicatesWithinSession() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()

        expect(tracker.trackPaywallClose()) == false

        tracker.trackPaywallImpression(Self.eventData)

        expect(tracker.trackPaywallClose()) == true
        expect(tracker.trackPaywallClose()) == false

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))

        let closeEvent = try XCTUnwrap(trackedEvents.value.last)
        if case .close = closeEvent {
            expect(closeEvent.data.sessionIdentifier) == Self.eventData.sessionIdentifier
        } else {
            fail("Expected close event")
        }
    }

    func testTrackPaywallImpressionAutoTracksCloseForPreviousSession() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()
        let firstEventData = Self.makeEventData()
        let secondEventData = Self.makeEventData()

        tracker.trackPaywallImpression(firstEventData)
        tracker.trackPaywallImpression(secondEventData)

        await expect(trackedEvents.value).toEventually(haveCount(3), timeout: .seconds(2))

        let closeEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .close = $0 { return true }
            return false
        }))
        let secondImpression = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .impression = $0 {
                return $0.data.sessionIdentifier == secondEventData.sessionIdentifier
            }
            return false
        }))

        if case .close = closeEvent {
            expect(closeEvent.data.sessionIdentifier) == firstEventData.sessionIdentifier
        } else {
            fail("Expected a close event for the previous session")
        }

        if case .impression = secondImpression {
            expect(secondImpression.data.sessionIdentifier) == secondEventData.sessionIdentifier
        } else {
            fail("Expected an impression event for the next session")
        }
    }

    func testTrackComponentInteractionSendsExpectedPaywallEvent() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()

        expect(tracker.trackComponentInteraction(componentType: .tab, componentName: nil, componentValue: "a")) == false

        tracker.trackPaywallImpression(Self.eventData)

        // swiftlint:disable:next line_length
        expect(tracker.trackComponentInteraction(componentType: .tab, componentName: "n", componentValue: "id1")) == true

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))

        let interactionEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .componentInteraction = $0 { return true }
            return false
        }))

        guard case let .componentInteraction(_, data, interaction) = interactionEvent else {
            fail("Expected componentInteraction event")
            return
        }

        expect(data.sessionIdentifier) == Self.eventData.sessionIdentifier
        expect(interaction.componentType) == .tab
        expect(interaction.componentName) == "n"
        expect(interaction.componentValue) == "id1"
    }

    func testTrackComponentInteraction_TextTypeIncludesComponentURLForMarkdownLinkStyle() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()

        let linkURL = try XCTUnwrap(URL(string: "https://example.com/doc"))
        tracker.trackPaywallImpression(Self.eventData)

        expect(tracker.trackComponentInteraction(
            componentType: .text,
            componentName: nil,
            componentValue: "navigate_to_url",
            componentURL: linkURL
        )) == true

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))

        let interactionEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .componentInteraction = $0 { return true }
            return false
        }))

        guard case let .componentInteraction(_, _, interaction) = interactionEvent else {
            fail("Expected componentInteraction event")
            return
        }

        expect(interaction.componentType) == .text
        expect(interaction.componentValue) == "navigate_to_url"
        expect(interaction.componentURL) == linkURL
        expect(interaction.componentName).to(beNil())
    }

    func testTrackComponentInteraction_StoresNavigationMetadataWhenProvided() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()

        tracker.trackPaywallImpression(Self.eventData)

        expect(tracker.trackComponentInteraction(
            componentType: .tab,
            componentName: "plans_tabs",
            componentValue: "annual",
            originIndex: 0,
            destinationIndex: 1,
            originContextName: "monthly",
            destinationContextName: "annual",
            defaultIndex: 0
        )) == true

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))

        let interactionEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .componentInteraction = $0 { return true }
            return false
        }))

        guard case let .componentInteraction(_, _, interaction) = interactionEvent else {
            fail("Expected componentInteraction event")
            return
        }

        expect(interaction.componentType) == .tab
        expect(interaction.componentName) == "plans_tabs"
        expect(interaction.componentValue) == "annual"
        expect(interaction.originIndex) == 0
        expect(interaction.destinationIndex) == 1
        expect(interaction.originContextName) == "monthly"
        expect(interaction.destinationContextName) == "annual"
        expect(interaction.defaultIndex) == 0
    }

    func testCreatePurchaseInitiatedEventAddsPurchaseInfoFromSession() throws {
        let (tracker, _) = Self.makeTracker()

        expect(tracker.createPurchaseInitiatedEvent(package: TestData.packageWithIntroOffer)).to(beNil())

        tracker.trackPaywallImpression(Self.eventData)

        let event = try XCTUnwrap(tracker.createPurchaseInitiatedEvent(package: TestData.packageWithIntroOffer))

        if case .purchaseInitiated = event {
            expect(event.data.packageId) == TestData.packageWithIntroOffer.identifier
            expect(event.data.productId) == TestData.packageWithIntroOffer.storeProduct.productIdentifier
            expect(event.data.sessionIdentifier) == Self.eventData.sessionIdentifier
        } else {
            fail("Expected purchaseInitiated event")
        }
    }

    func testTrackPurchaseErrorAddsPurchaseInfoFromSession() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()
        let error = NSError(domain: "test", code: 7, userInfo: [NSLocalizedDescriptionKey: "broken"])

        expect(tracker.trackPurchaseError(package: TestData.packageWithIntroOffer, error: error)) == false

        tracker.trackPaywallImpression(Self.eventData)

        expect(tracker.trackPurchaseError(package: TestData.packageWithIntroOffer, error: error)) == true

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))

        let errorEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .purchaseError = $0 { return true }
            return false
        }))

        if case .purchaseError = errorEvent {
            expect(errorEvent.data.packageId) == TestData.packageWithIntroOffer.identifier
            expect(errorEvent.data.productId) == TestData.packageWithIntroOffer.storeProduct.productIdentifier
            expect(errorEvent.data.errorCode) == error.code
            expect(errorEvent.data.errorMessage) == error.localizedDescription
        } else {
            fail("Expected purchaseError event")
        }
    }

    func testTrackCancelledPurchaseAddsPurchaseInfoFromSession() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()

        expect(tracker.trackCancelledPurchase(package: TestData.packageWithIntroOffer)) == false

        tracker.trackPaywallImpression(Self.eventData)

        expect(tracker.trackCancelledPurchase(package: TestData.packageWithIntroOffer)) == true

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))

        let cancelEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .cancel = $0 { return true }
            return false
        }))

        if case .cancel = cancelEvent {
            expect(cancelEvent.data.packageId) == TestData.packageWithIntroOffer.identifier
            expect(cancelEvent.data.productId) == TestData.packageWithIntroOffer.storeProduct.productIdentifier
            expect(cancelEvent.data.errorCode).to(beNil())
            expect(cancelEvent.data.errorMessage).to(beNil())
        } else {
            fail("Expected cancel event")
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallEventTrackerTests {

    static let eventData: PaywallEvent.Data = .init(
        offering: TestData.offeringWithIntroOffer,
        paywall: TestData.paywallWithIntroOffer,
        sessionID: .init(),
        displayMode: .fullScreen,
        locale: .init(identifier: "en_US"),
        darkMode: false,
        source: nil
    )

    static func makeEventData() -> PaywallEvent.Data {
        return .init(
        offering: TestData.offeringWithIntroOffer,
        paywall: TestData.paywallWithIntroOffer,
        sessionID: .init(),
        displayMode: .fullScreen,
        locale: .init(identifier: "en_US"),
        darkMode: false,
        source: nil
        )
    }

    static func makeTracker() -> (tracker: PaywallEventTracker, trackedEvents: Atomic<[PaywallEvent]>) {
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
            eventDispatcher: PurchaseHandler.testEventDispatcher
        )

        return (tracker, trackedEvents)
    }

}
