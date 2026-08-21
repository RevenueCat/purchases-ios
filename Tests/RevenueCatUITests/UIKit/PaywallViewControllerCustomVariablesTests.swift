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
@testable import RevenueCatUI
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
