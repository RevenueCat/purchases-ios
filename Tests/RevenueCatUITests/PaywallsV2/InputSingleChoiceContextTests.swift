//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InputSingleChoiceContextTests.swift

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class InputSingleChoiceContextTests: TestCase {

    func testInitialSelectionIsNil() {
        let context = InputSingleChoiceContext(fieldId: "plan_type")
        expect(context.selectedOptionId).to(beNil())
    }

    func testSelectingOptionUpdatesSelection() {
        let context = InputSingleChoiceContext(fieldId: "plan_type")
        context.selectedOptionId = "annual"
        expect(context.selectedOptionId) == "annual"
    }

    func testSelectingDifferentOptionReplacesSelection() {
        let context = InputSingleChoiceContext(fieldId: "plan_type")
        context.selectedOptionId = "annual"
        context.selectedOptionId = "monthly"
        expect(context.selectedOptionId) == "monthly"
    }

    func testFieldIdIsPreserved() {
        let context = InputSingleChoiceContext(fieldId: "survey_answer")
        expect(context.fieldId) == "survey_answer"
    }

}

#endif
