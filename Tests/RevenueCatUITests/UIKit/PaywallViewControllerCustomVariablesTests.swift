//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewControllerCustomVariablesTests.swift
//
//  Created by Rick van der Linden.
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class PaywallCustomVariablesTests: TestCase {

    func testCustomVariablesPropertyFiltersInvalidKeys() {
        let controller = PaywallViewController(offering: Self.offering)

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
        let controller = PaywallViewController(offering: Self.offering)

        controller.setCustomVariable("kept", forKey: "string_value")
        controller.setCustomVariableNumber(2, forKey: "number-value")
        controller.setCustomVariableBool(true, forKey: "1boolean")

        expect(controller.customVariables).to(equal([
            "string_value": "kept",
            "1boolean": true
        ]))
    }

    func testOfferingIdentifierWithContextPurchaseLogicAllowsConfigurationBeforeLoading() {
        let controller = PaywallViewController(
            offeringIdentifier: "main",
            presentedOfferingContext: .init(offeringIdentifier: "main"),
            performPurchaseWithContext: { _ in (userCancelled: false, error: nil) },
            performRestore: { (success: true, error: nil) }
        )

        expect(controller.isViewLoaded).to(beFalse())

        controller.setCustomVariable("premium", forKey: "tier")
        controller.setCustomVariableNumber(2, forKey: "count")
        controller.setCustomVariableBool(true, forKey: "is_pro")

        expect(controller.isViewLoaded).to(beFalse())
        controller.loadViewIfNeeded()
        expect(controller.customVariables).to(equal([
            "tier": .string("premium"),
            "count": .number(2),
            "is_pro": .bool(true)
        ]))
    }

    func testCustomVariablesSetAfterLoadingUpdateDisplayedPaywall() {
        let controller = PaywallViewController(offering: Self.offering)
        controller.setCustomVariable("100", forKey: "coin_balance")
        controller.loadViewIfNeeded()

        let hostingController = controller.hostingControllerForTesting
        expect(hostingController).notTo(beNil(), description: "precondition")

        controller.setCustomVariable("250", forKey: "coin_balance")

        expect(controller.displayedCustomVariablesForTesting).to(equal([
            "coin_balance": .string("250")
        ]))
        expect(controller.hostingControllerForTesting).to(beIdenticalTo(hostingController))
    }

    func testCustomVariablesPropertySetAfterLoadingFiltersInvalidKeys() {
        let controller = PaywallViewController(offering: Self.offering)
        controller.loadViewIfNeeded()

        controller.customVariables = [
            "valid_key": "kept",
            "invalid-key": "dropped"
        ]

        expect(controller.displayedCustomVariablesForTesting).to(equal([
            "valid_key": "kept"
        ]))
    }

    private static let offering = Offering(
        identifier: "main",
        serverDescription: "Main offering",
        metadata: [:],
        paywall: nil,
        availablePackages: [],
        webCheckoutUrl: nil
    )

}

#endif
