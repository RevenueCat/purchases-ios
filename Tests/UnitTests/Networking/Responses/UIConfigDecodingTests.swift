//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIConfigDecodingTests.swift
//
//  Created by Josh Holtz on 12/31/24.

import Nimble
@testable import RevenueCat
import XCTest

#if PAYWALL_COMPONENTS

class UIConfigDecodingTests: BaseHTTPResponseTest {

    func testDecodesPaywallData() throws {
        let uiConfig: UIConfig = try self.decodeFixture("UIConfig")

        expect(uiConfig.app.colors).to(equal([
            "primary": .hex("#ffcc00"),
            "secondary": .linear(45, [
                .init(color: "#032400ff", percent: 0),
                .init(color: "#090979ff", percent: 35),
                .init(color: "#216c32ff", percent: 100)
            ]),
            "tertiary": .radial([
                .init(color: "#032400ff", percent: 0),
                .init(color: "#090979ff", percent: 35),
                .init(color: "#216c32ff", percent: 100)
            ])
        ]))
        expect(uiConfig.app.fonts).to(equal(
            .init(ios: .name("SF Pro"))
        ))

        expect(uiConfig.localizations).to(equal([
            "en_US": [
                "monthly": "monthly"
            ],
            "es_ES": [
                "monthly": "mensual"
            ]
        ]))

        expect(uiConfig.variableConfig.variableCompatibilityMap).to(equal([
            "new var": "guaranteed var"
        ]))
        expect(uiConfig.variableConfig.functionCompatibilityMap).to(equal([
            "new fun": "guaranteed fun"
        ]))
    }

}

#endif
