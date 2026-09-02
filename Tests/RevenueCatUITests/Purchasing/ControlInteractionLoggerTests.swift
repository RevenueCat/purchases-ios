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
@_spi(Internal) @testable import RevenueCatUI
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

    func testOnInteractionHandlerReceivesContractKeysOnlyAfterImpression() async throws {
        let tracker = PaywallEventTracker(
            purchases: MockPurchases(
                purchase: { _, _, _ in
                    (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
                },
                restorePurchases: { TestData.customerInfo },
                trackEvent: { _ in },
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
            componentType: .tab,
            componentName: "plans",
            componentValue: "annual",
            originIndex: 0,
            destinationIndex: 1
        )
        let received: Atomic<[PaywallInteractionEvent]> = .init([])
        let logger = tracker.componentInteractionLogger(sessionID: eventData.sessionIdentifier) { event in
            received.modify { $0.append(event) }
        }

        expect(logger(interactionData)) == false
        await Task.yield()
        expect(received.value).to(beEmpty())

        tracker.trackPaywallImpression(eventData)
        expect(logger(interactionData)) == true
        await expect(received.value).toEventually(haveCount(1))

        let event = try XCTUnwrap(received.value.first)
        expect(Set(event.rawProperties.keys).isSubset(of: PaywallInteractionEvent.Keys.all)) == true
        expect(event.property(for: PaywallInteractionEvent.Keys.sessionId)) == eventData.sessionIdentifier.uuidString
        expect(event.property(for: PaywallInteractionEvent.Keys.offeringId)) == eventData.offeringIdentifier
        expect(event.property(for: PaywallInteractionEvent.Keys.componentType))
            == PaywallInteractionEvent.ComponentTypes.tab
        expect(event.property(for: PaywallInteractionEvent.Keys.componentValue)) == "annual"
        expect(event.property(for: PaywallInteractionEvent.Keys.componentName)) == "plans"
        expect(event.property(for: PaywallInteractionEvent.Keys.originIndex)) == 0
        expect(event.property(for: PaywallInteractionEvent.Keys.destinationIndex)) == 1
        expect(event.property(for: PaywallInteractionEvent.Keys.darkMode)) == false
        expect(event.property(for: PaywallInteractionEvent.Keys.timestamp)).toNot(beNil())
        expect(event.property(for: PaywallInteractionEvent.Keys.componentUrl)).to(beNil())
    }

    func testOnInteractionHandlerReceivesEveryContractKeyWhenFullyPopulated() async throws {
        let tracker = PaywallEventTracker(
            purchases: MockPurchases(
                purchase: { _, _, _ in
                    (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
                },
                restorePurchases: { TestData.customerInfo },
                trackEvent: { _ in },
                customerInfo: { TestData.customerInfo }
            ),
            eventDispatcher: PaywallEventTrackerTestDispatcher.value
        )
        let eventData: PaywallEvent.Data = .init(
            paywallIdentifier: "pw_123",
            offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
            paywallRevision: 7,
            sessionID: .init(),
            displayMode: .fullScreen,
            localeIdentifier: "en_US",
            darkMode: false
        )
        let interactionData = PaywallEvent.ComponentInteractionData(
            componentType: .carousel,
            componentName: "hero",
            componentValue: "page_change",
            componentURL: URL(string: "https://example.com"),
            originIndex: 0,
            destinationIndex: 1,
            originContextName: "first",
            destinationContextName: "second",
            defaultIndex: 0,
            originPackageIdentifier: "monthly",
            destinationPackageIdentifier: "annual",
            defaultPackageIdentifier: "monthly",
            originProductIdentifier: "com.app.monthly",
            destinationProductIdentifier: "com.app.annual",
            defaultProductIdentifier: "com.app.monthly",
            currentPackageIdentifier: "monthly",
            resultingPackageIdentifier: "annual",
            currentProductIdentifier: "com.app.monthly",
            resultingProductIdentifier: "com.app.annual"
        )
        let received: Atomic<[PaywallInteractionEvent]> = .init([])
        let logger = tracker.componentInteractionLogger(sessionID: eventData.sessionIdentifier) { event in
            received.modify { $0.append(event) }
        }

        tracker.trackPaywallImpression(eventData)
        expect(logger(interactionData)) == true
        await expect(received.value).toEventually(haveCount(1))

        let event = try XCTUnwrap(received.value.first)
        expect(PaywallInteractionEvent.Keys.all).to(haveCount(27))
        expect(Set(event.rawProperties.keys)) == PaywallInteractionEvent.Keys.all
        let wireKeys = Set(PaywallEvent.componentInteraction(.init(), eventData, interactionData).paywallMap().keys)
        expect(wireKeys.subtracting(["discriminator", "type", "id"])) == PaywallInteractionEvent.Keys.all
        expect(event.property(for: PaywallInteractionEvent.Keys.paywallId)) == "pw_123"
        expect(event.property(for: PaywallInteractionEvent.Keys.componentUrl)) == "https://example.com"
        expect(event.property(for: PaywallInteractionEvent.Keys.resultingProductId)) == "com.app.annual"
    }

    func testComponentTypeConstantsMatchWireValues() {
        typealias WireType = ComponentInteractionType
        typealias Constants = PaywallInteractionEvent.ComponentTypes

        expect(Constants.tab) == WireType.tab.rawValue
        expect(Constants.switch) == WireType.toggleSwitch.rawValue
        expect(Constants.carousel) == WireType.carousel.rawValue
        expect(Constants.button) == WireType.button.rawValue
        expect(Constants.text) == WireType.text.rawValue
        expect(Constants.package) == WireType.package.rawValue
        expect(Constants.packageSelectionSheet) == WireType.packageSelectionSheet.rawValue
        expect(Constants.purchaseButton) == WireType.purchaseButton.rawValue
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
