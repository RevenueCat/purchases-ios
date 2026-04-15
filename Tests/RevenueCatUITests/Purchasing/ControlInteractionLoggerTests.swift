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

        expect(await logger(interactionData)) == false

        await tracker.trackPaywallImpression(eventData)

        expect(await logger(interactionData)) == true

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

    // MARK: - paywallPurchaseButtonAction factory

    func testPurchaseButtonActionFactory_setsComponentTypeToPurchaseButton() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: "buy_button",
            componentValue: "in_app_checkout"
        )

        expect(data.componentType) == .purchaseButton
    }

    func testPurchaseButtonActionFactory_setsComponentName() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: "my_button",
            componentValue: "in_app_checkout"
        )

        expect(data.componentName) == "my_button"
    }

    func testPurchaseButtonActionFactory_nilComponentNameIsPreserved() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: nil,
            componentValue: "in_app_checkout"
        )

        expect(data.componentName).to(beNil())
    }

    func testPurchaseButtonActionFactory_setsComponentValue() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: nil,
            componentValue: "web_checkout"
        )

        expect(data.componentValue) == "web_checkout"
    }

    func testPurchaseButtonActionFactory_setsComponentURL() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/checkout"))

        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: nil,
            componentValue: "custom_web_checkout",
            componentURL: url
        )

        expect(data.componentURL) == url
    }

    func testPurchaseButtonActionFactory_nilComponentURLIsPreserved() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: nil,
            componentValue: "in_app_checkout",
            componentURL: nil
        )

        expect(data.componentURL).to(beNil())
    }

    func testPurchaseButtonActionFactory_setsCurrentPackageIdentifier() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: nil,
            componentValue: "in_app_checkout",
            currentPackageIdentifier: "annual"
        )

        expect(data.currentPackageIdentifier) == "annual"
    }

    func testPurchaseButtonActionFactory_setsCurrentProductIdentifier() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: nil,
            componentValue: "in_app_checkout",
            currentProductIdentifier: "com.app.annual"
        )

        expect(data.currentProductIdentifier) == "com.app.annual"
    }

    func testPurchaseButtonActionFactory_nilPackageAndProductIdentifiersArePreserved() {
        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: nil,
            componentValue: "in_app_checkout"
        )

        expect(data.currentPackageIdentifier).to(beNil())
        expect(data.currentProductIdentifier).to(beNil())
    }

    func testPurchaseButtonActionFactory_allFieldsPopulated() throws {
        let url = try XCTUnwrap(URL(string: "https://rc.example.com/checkout"))

        let data = PaywallEvent.ComponentInteractionData.paywallPurchaseButtonAction(
            componentName: "cta_button",
            componentValue: "custom_web_checkout",
            componentURL: url,
            currentPackageIdentifier: "monthly",
            currentProductIdentifier: "com.app.monthly"
        )

        expect(data.componentType) == .purchaseButton
        expect(data.componentName) == "cta_button"
        expect(data.componentValue) == "custom_web_checkout"
        expect(data.componentURL) == url
        expect(data.currentPackageIdentifier) == "monthly"
        expect(data.currentProductIdentifier) == "com.app.monthly"
    }

}
