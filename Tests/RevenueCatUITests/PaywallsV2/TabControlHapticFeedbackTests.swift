//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabControlHapticFeedbackTests.swift

@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabControlHapticFeedbackTests: TestCase {

    func testShouldTriggerHapticFeedback_whenTabChangesAndEnabled_returnsTrue() {
        XCTAssertTrue(
            TabControlButtonComponentView.shouldTriggerHapticFeedback(
                originTabId: "weekly",
                destinationTabId: "annual",
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenTabUnchanged_returnsFalse() {
        XCTAssertFalse(
            TabControlButtonComponentView.shouldTriggerHapticFeedback(
                originTabId: "weekly",
                destinationTabId: "weekly",
                hapticFeedbackEnabled: true
            )
        )
    }

    func testShouldTriggerHapticFeedback_whenDisabled_returnsFalseEvenIfTabChanges() {
        XCTAssertFalse(
            TabControlButtonComponentView.shouldTriggerHapticFeedback(
                originTabId: "weekly",
                destinationTabId: "annual",
                hapticFeedbackEnabled: false
            )
        )
    }

}

#endif
