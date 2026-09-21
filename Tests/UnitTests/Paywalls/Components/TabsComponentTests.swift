//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentTests.swift

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

class TabsComponentTests: TestCase {

    // MARK: - TabControlButtonComponent

    func testTabControlButtonHapticFeedbackEnabledDefaultsToNilWhenOmitted() {
        let component = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: [])
        )

        XCTAssertNil(component.hapticFeedbackEnabled)
    }

    func testTabControlButtonHapticFeedbackEnabledRoundTripsTrueAndFalse() throws {
        let enabled = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: []),
            hapticFeedbackEnabled: true
        )
        let disabled = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: []),
            hapticFeedbackEnabled: false
        )

        XCTAssertEqual(try enabled.encodeAndDecode().hapticFeedbackEnabled, true)
        XCTAssertEqual(try disabled.encodeAndDecode().hapticFeedbackEnabled, false)
        XCTAssertNotEqual(enabled, disabled)
    }

    func testTabControlButtonHapticFeedbackEnabledDecodesFromSnakeCaseWireKey() throws {
        let component = PaywallComponent.TabControlButtonComponent(
            tabId: "weekly",
            stack: PaywallComponent.StackComponent(components: [])
        )
        let encoded = try JSONEncoder.default.encode(component)

        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["haptic_feedback_enabled"] = false

        let patchedData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.TabControlButtonComponent.self,
            from: patchedData
        )

        XCTAssertEqual(decoded.hapticFeedbackEnabled, false)
    }

    // MARK: - TabControlToggleComponent

    private func makeToggleComponent(hapticFeedbackEnabled: Bool?) -> PaywallComponent.TabControlToggleComponent {
        return PaywallComponent.TabControlToggleComponent(
            defaultValue: false,
            thumbColorOn: .init(light: .hex("#00ff00")),
            thumbColorOff: .init(light: .hex("#ff0000")),
            trackColorOn: .init(light: .hex("#dedede")),
            trackColorOff: .init(light: .hex("#bebebe")),
            hapticFeedbackEnabled: hapticFeedbackEnabled
        )
    }

    func testTabControlToggleHapticFeedbackEnabledDefaultsToNilWhenOmitted() {
        let component = PaywallComponent.TabControlToggleComponent(
            defaultValue: false,
            thumbColorOn: .init(light: .hex("#00ff00")),
            thumbColorOff: .init(light: .hex("#ff0000")),
            trackColorOn: .init(light: .hex("#dedede")),
            trackColorOff: .init(light: .hex("#bebebe"))
        )

        XCTAssertNil(component.hapticFeedbackEnabled)
    }

    func testTabControlToggleHapticFeedbackEnabledRoundTripsTrueAndFalse() throws {
        let enabled = self.makeToggleComponent(hapticFeedbackEnabled: true)
        let disabled = self.makeToggleComponent(hapticFeedbackEnabled: false)

        XCTAssertEqual(try enabled.encodeAndDecode().hapticFeedbackEnabled, true)
        XCTAssertEqual(try disabled.encodeAndDecode().hapticFeedbackEnabled, false)
        XCTAssertNotEqual(enabled, disabled)
    }

    func testTabControlToggleHapticFeedbackEnabledDecodesFromSnakeCaseWireKey() throws {
        let component = self.makeToggleComponent(hapticFeedbackEnabled: nil)
        let encoded = try JSONEncoder.default.encode(component)

        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json["haptic_feedback_enabled"] = false

        let patchedData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder.default.decode(
            PaywallComponent.TabControlToggleComponent.self,
            from: patchedData
        )

        XCTAssertEqual(decoded.hapticFeedbackEnabled, false)
    }

}
