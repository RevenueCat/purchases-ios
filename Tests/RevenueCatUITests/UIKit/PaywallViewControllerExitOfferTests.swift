//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewControllerExitOfferTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class PaywallViewControllerExitOfferTests: TestCase {

    func testUpdateDisplayCloseButtonDoesNotClearWorkflowExitOffer() {
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "main"))
        controller.simulateWorkflowExitOfferUpdate(Self.makeOffering(identifier: "exit"))
        expect(controller.exitOfferOfferingForTesting).notTo(beNil(), description: "precondition")

        controller.update(with: true) // displayCloseButton — non-content mutation

        expect(controller.exitOfferOfferingForTesting).notTo(
            beNil(),
            description: "update(with displayCloseButton:) must not clear the workflow exit offer"
        )
    }

    func testUpdateFontDoesNotClearWorkflowExitOffer() {
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "main"))
        controller.simulateWorkflowExitOfferUpdate(Self.makeOffering(identifier: "exit"))
        expect(controller.exitOfferOfferingForTesting).notTo(beNil(), description: "precondition")

        controller.updateFont(with: "Papyrus")

        expect(controller.exitOfferOfferingForTesting).notTo(
            beNil(),
            description: "updateFont(with:) must not clear the workflow exit offer"
        )
    }

    func testUpdateOfferingClearsWorkflowExitOffer() {
        // Replacing the offering is a legitimate reason to drop the previous exit offer —
        // the new paywall will re-emit one.
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "original"))
        controller.simulateWorkflowExitOfferUpdate(Self.makeOffering(identifier: "exit"))
        expect(controller.exitOfferOfferingForTesting).notTo(beNil(), description: "precondition")

        controller.update(with: Self.makeOffering(identifier: "replacement"))

        expect(controller.exitOfferOfferingForTesting).to(
            beNil(),
            description: "Replacing the offering should clear the stale exit offer"
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewControllerExitOfferTests {

    static func makeOffering(identifier: String) -> Offering {
        return Offering(
            identifier: identifier,
            serverDescription: "Offering \(identifier)",
            metadata: [:],
            paywall: nil,
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

}

#endif
