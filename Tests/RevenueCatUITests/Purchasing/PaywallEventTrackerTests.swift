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

        expect(tracker.trackComponentInteraction(
            .init(componentType: .tab, componentName: nil, componentValue: "a"))
        ) == false

        tracker.trackPaywallImpression(Self.eventData)

        expect(tracker.trackComponentInteraction(
            .init(componentType: .tab, componentName: "n", componentValue: "id1"))
        ) == true

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

        expect(tracker.trackComponentInteraction(.init(
            componentType: .text,
            componentName: nil,
            componentValue: "navigate_to_url",
            componentURL: linkURL
        ))) == true

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

        expect(tracker.trackComponentInteraction(.init(
            componentType: .tab,
            componentName: "plans_tabs",
            componentValue: "annual",
            originIndex: 0,
            destinationIndex: 1,
            originContextName: "monthly",
            destinationContextName: "annual",
            defaultIndex: 0
        ))) == true

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

    func testTrackComponentInteraction_IncludesPlanSelectionMetadataWhenProvided() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()

        tracker.trackPaywallImpression(Self.eventData)

        expect(tracker.trackComponentInteraction(.init(
            componentType: .package,
            componentName: "annual_package",
            componentValue: "annual",
            originPackageIdentifier: "monthly",
            destinationPackageIdentifier: "annual",
            defaultPackageIdentifier: "annual",
            originProductIdentifier: "com.monthly",
            destinationProductIdentifier: "com.annual",
            defaultProductIdentifier: "com.annual"
        ))) == true

        await expect(trackedEvents.value).toEventually(haveCount(2), timeout: .seconds(2))

        let interactionEvent = try XCTUnwrap(trackedEvents.value.first(where: {
            if case .componentInteraction = $0 { return true }
            return false
        }))

        guard case let .componentInteraction(_, _, interaction) = interactionEvent else {
            fail("Expected componentInteraction event")
            return
        }

        expect(interaction.componentType) == .package
        expect(interaction.originPackageIdentifier) == "monthly"
        expect(interaction.destinationPackageIdentifier) == "annual"
        expect(interaction.defaultPackageIdentifier) == "annual"
        expect(interaction.originProductIdentifier) == "com.monthly"
        expect(interaction.destinationProductIdentifier) == "com.annual"
        expect(interaction.defaultProductIdentifier) == "com.annual"
    }

    func testTrackComponentInteraction_IncludesPackageSelectionSheetLifecycleMetadataWhenProvided() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()

        tracker.trackPaywallImpression(Self.eventData)

        let sheetAnalyticsName = "all_plans_sheet"

        expect(tracker.trackComponentInteraction(
            .paywallPackageSelectionSheetOpen(
                sheetComponentName: sheetAnalyticsName,
                rootSelectedPackage: TestData.weeklyPackage
            )
        )) == true

        expect(tracker.trackComponentInteraction(
            .paywallPackageSelectionSheetClose(
                sheetComponentName: sheetAnalyticsName,
                sheetSelectedPackage: TestData.monthlyPackage,
                resultingRootPackage: TestData.weeklyPackage
            )
        )) == true

        await expect(trackedEvents.value).toEventually(haveCount(3), timeout: .seconds(2))

        let sheetEvents = trackedEvents.value.compactMap { event -> PaywallEvent.ComponentInteractionData? in
            guard case let .componentInteraction(_, _, interaction) = event else { return nil }
            guard interaction.componentType == .packageSelectionSheet else { return nil }
            return interaction
        }
        expect(sheetEvents).to(haveCount(2))

        let openInteraction = try XCTUnwrap(sheetEvents.first { $0.componentValue == "open" })
        expect(openInteraction.componentName) == sheetAnalyticsName
        expect(openInteraction.currentPackageIdentifier) == TestData.weeklyPackage.identifier
        expect(openInteraction.currentProductIdentifier) == TestData.weeklyPackage.storeProduct.productIdentifier
        expect(openInteraction.resultingPackageIdentifier).to(beNil())
        expect(openInteraction.resultingProductIdentifier).to(beNil())

        let closeInteraction = try XCTUnwrap(sheetEvents.first { $0.componentValue == "close" })
        expect(closeInteraction.componentName) == sheetAnalyticsName
        expect(closeInteraction.currentPackageIdentifier) == TestData.monthlyPackage.identifier
        expect(closeInteraction.currentProductIdentifier) == TestData.monthlyPackage.storeProduct.productIdentifier
        expect(closeInteraction.resultingPackageIdentifier) == TestData.weeklyPackage.identifier
        expect(closeInteraction.resultingProductIdentifier) == TestData.weeklyPackage.storeProduct.productIdentifier
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

    func testConcurrentCloseAndComponentInteractionAreThreadSafe() async throws {
        let (tracker, trackedEvents) = Self.makeTracker()
        tracker.trackPaywallImpression(Self.eventData)

        let closeSuccessCount = Atomic<Int>(0)
        let interactionSuccessCount = Atomic<Int>(0)
        let concurrentCalls = 40

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<concurrentCalls {
                group.addTask {
                    let closeTracked = tracker.trackPaywallClose()
                    if closeTracked {
                        closeSuccessCount.modify { $0 += 1 }
                    }
                }

                group.addTask {
                    let interactionTracked = tracker.trackComponentInteraction(
                        .init(
                            componentType: .tab,
                            componentName: "concurrent_tab",
                            componentValue: "index_\(index)"
                        )
                    )
                    if interactionTracked {
                        interactionSuccessCount.modify { $0 += 1 }
                    }
                }
            }
        }

        expect(closeSuccessCount.value) == 1
        expect(interactionSuccessCount.value) == concurrentCalls

        await expect(trackedEvents.value).toEventually(haveCount(1 + 1 + concurrentCalls), timeout: .seconds(2))

        let closeEvents = trackedEvents.value.filter { event in
            if case .close = event { return true }
            return false
        }
        expect(closeEvents).to(haveCount(1))
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
            eventDispatcher: { work in
                Task { await work() }
            }
        )

        return (tracker, trackedEvents)
    }
}
