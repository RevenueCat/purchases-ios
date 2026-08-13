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

    func testCustomVariablesPropertyFiltersInvalidKeys() {
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "main"))

        controller.customVariables = [
            "valid_key": "kept",
            "invalid-key": "dropped",
            "2fast": "also kept"
        ]

        expect(controller.customVariables).to(equal([
            "valid_key": "kept",
            "2fast": "also kept"
        ]))
    }

    func testObjectiveCCustomVariableSettersFilterInvalidKeys() {
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "main"))

        controller.setCustomVariable("kept", forKey: "string_value")
        controller.setCustomVariableNumber(2, forKey: "number-value")
        controller.setCustomVariableBool(true, forKey: "1boolean")

        expect(controller.customVariables).to(equal([
            "string_value": "kept",
            "1boolean": true
        ]))
    }

    func testUpdateDisplayCloseButtonDoesNotClearWorkflowExitOffer() {
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "main"))
        controller.remoteConfigEnabledForTesting = true

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
        controller.remoteConfigEnabledForTesting = true

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
        controller.remoteConfigEnabledForTesting = true

        controller.simulateWorkflowExitOfferUpdate(Self.makeOffering(identifier: "exit"))
        expect(controller.exitOfferOfferingForTesting).notTo(beNil(), description: "precondition")

        controller.update(with: Self.makeOffering(identifier: "replacement"))

        expect(controller.exitOfferOfferingForTesting).to(
            beNil(),
            description: "Replacing the offering should clear the stale exit offer"
        )
    }

    func testLateOfferingBasedPrefetchDoesNotRestoreOfferAfterWorkflowReportsNone() {
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "main"))
        controller.remoteConfigEnabledForTesting = true

        // The workflow resolves first and deliberately has no exit offer for this step.
        controller.simulateWorkflowExitOfferUpdate(nil)

        // A slower offering-based prefetch, kicked off before the workflow reported in, resolves after it.
        controller.simulateOfferingBasedExitOfferPrefetchResult(Self.makeOffering(identifier: "stale-exit"))

        expect(controller.exitOfferOfferingForTesting).to(
            beNil(),
            description: "a late offering-based prefetch must not restore an offer once the workflow has reported none"
        )
    }

    func testOfferingBasedPrefetchStillWritesAfterControllerInitiatedContentReset() {
        let controller = PaywallViewController(offering: Self.makeOffering(identifier: "original"))
        controller.remoteConfigEnabledForTesting = true

        // A caller replaces the content before the embedded workflow paywall has rendered anything.
        controller.update(with: Self.makeOffering(identifier: "replacement"))

        // The single offering-based prefetch kicked off at load resolves afterward against the new content.
        controller.simulateOfferingBasedExitOfferPrefetchResult(Self.makeOffering(identifier: "offering-based-exit"))

        expect(controller.exitOfferOfferingForTesting).notTo(
            beNil(),
            description: "resetting content for a new render must not permanently block the offering-based prefetch"
        )
    }

    // MARK: - Exit offer dismissal

    // The exit-offer controller is created and presented by the SDK, so the SDK has to dismiss it.
    // Forwarding to the host's handler alone strands the exit offer whenever that handler dismisses
    // its own captured controller instead of the one it is handed — a common shape, since the host
    // wrote it for the paywall it presented itself.
    func testExitOfferIsDismissedEvenWhenHostHandlerIgnoresTheGivenController() {
        var hostHandlerCallCount = 0
        let handler = PaywallViewController.exitOfferDismissRequestedHandler(
            originalHandler: { _ in
                // Host dismisses whatever it captured for the first paywall; the argument is ignored.
                hostHandlerCallCount += 1
            }
        )

        let exitOffer = DismissRecordingPaywallViewController(offering: Self.makeOffering(identifier: "exit"))
        handler(exitOffer)

        expect(exitOffer.dismissCallCount).to(
            equal(1),
            description: "the SDK must dismiss the exit offer controller it presented"
        )
        expect(hostHandlerCallCount).to(
            equal(1),
            description: "the host handler must still be called, so existing close callbacks keep firing"
        )
    }

    func testExitOfferIsDismissedWhenHostHasNoHandler() {
        let handler = PaywallViewController.exitOfferDismissRequestedHandler(originalHandler: nil)

        let exitOffer = DismissRecordingPaywallViewController(offering: Self.makeOffering(identifier: "exit"))
        handler(exitOffer)

        expect(exitOffer.dismissCallCount).to(equal(1))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private final class DismissRecordingPaywallViewController: PaywallViewController {

    private(set) var dismissCallCount = 0

    init(offering: Offering) {
        super.init(
            content: .offering(offering),
            fonts: DefaultPaywallFontProvider(),
            displayCloseButton: false,
            shouldBlockTouchEvents: false,
            performPurchase: nil,
            performRestore: nil,
            dismissRequestedHandler: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        self.dismissCallCount += 1
        completion?()
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
