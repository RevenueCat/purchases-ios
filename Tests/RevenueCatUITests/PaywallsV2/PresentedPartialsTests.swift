//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PresentedPartialsTests.swift
//
//  Created by Josh Holtz on 1/25/25.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PresentedPartialsTest: TestCase {

    func testNoPresentedPartials() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.compact
        let isEligibleForIntroOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = []

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsCompactAppliedForCompact() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.compact
        let isEligibleForIntroOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .compact
            ], properties: .init(
                margin: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            margin: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsMediumNotAppliedForCompact() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.compact
        let isEligibleForIntroOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .medium
            ], properties: .init(
                margin: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsCompactAndMediumAppliedForMedium() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .compact
            ], properties: .init(
                padding: .zero,
                margin: .zero
            )),
            .init(conditions: [
                .medium
            ], properties: .init(
                spacing: 8,
                margin: .init(top: 2, bottom: 2, leading: 2, trailing: 2)
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            spacing: 8,
            padding: .zero,
            margin: .init(top: 2, bottom: 2, leading: 2, trailing: 2)
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsSelectedAppliedWhenSelected() {
        let state = ComponentViewState.selected
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selected
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            padding: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsSelectedNotAppliedWhenNotSelected() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .selected
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

    func testPresentedPartialsIntroOfferAppliedWhenIntroOffer() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = true

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .introOffer
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        let expected: PresentedStackPartial = .init(
            padding: .zero
        )

        expect(result).to(equal(expected))
    }

    func testPresentedPartialsIntroOfferNotAppliedWhenNotIntroOffer() {
        let state = ComponentViewState.default
        let condition = ScreenCondition.medium
        let isEligibleForIntroOffer = false

        let presentedOverrides: PresentedOverrides<PresentedStackPartial> = [
            .init(conditions: [
                .introOffer
            ], properties: .init(
                padding: .zero
            ))
        ]

        let result = PresentedStackPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: presentedOverrides
        )

        expect(result).to(beNil())
    }

}

#endif
