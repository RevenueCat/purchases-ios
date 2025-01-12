//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Untitled.swift
//
//  Created by Josh Holtz on 1/12/25.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PresentedPartialTest: TestCase {

    func testNothing() {
        let presentedOverrides: PresentedOverrides<LocalizedTextPartial>? = nil

        let localizedPartial = LocalizedTextPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            with: presentedOverrides
        )

        let expectedResult = LocalizedTextPartial(
            text: nil,
            partial: .init(
                visible: nil
            )
        )

        expect(localizedPartial).to(equal(expectedResult))
    }

    func testApp() {
        let presentedOverrides: PresentedOverrides<LocalizedTextPartial> = .init(
            app: .init(
                text: "override_id_app",
                partial: .init(
                    visible: nil,
                    fontSize: .bodyL
                )
            ),
            introOffer: nil,
            states: nil,
            conditions: nil
        )

        let localizedPartial = LocalizedTextPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            with: presentedOverrides
        )

        let expectedResult = LocalizedTextPartial(
            text: "override_id_app",
            partial: .init(
                visible: nil,
                fontSize: .bodyL
            )
        )

        expect(localizedPartial).to(equal(expectedResult))
    }

    func testConditionCompactOverridesApp() {
        let presentedOverrides: PresentedOverrides<LocalizedTextPartial> = .init(
            app: .init(
                text: "override_id_app",
                partial: .init(
                    visible: nil,
                    fontWeight: .light,
                    fontSize: .bodyL
                )
            ),
            introOffer: nil,
            states: nil,
            conditions: .init(
                compact: .init(
                    text: "override_id_compact",
                    partial: .init(
                        visible: nil,
                        fontSize: .bodyM
                    )
                ),
                // This won't get used because `buildPartial` since its using `compact
                medium: .init(
                    text: "override_id_medium",
                    partial: .init(
                        visible: nil,
                        horizontalAlignment: .trailing
                    )
                ),
                expanded: nil
            )
        )

        let localizedPartial = LocalizedTextPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            with: presentedOverrides
        )

        let expectedResult = LocalizedTextPartial(
            text: "override_id_compact", // From compact
            partial: .init(
                visible: nil,
                fontWeight: .light, // From app
                fontSize: .bodyM // From compact
            )
        )

        expect(localizedPartial).to(equal(expectedResult))
    }

    func testConditionMediumOverridesConditionCompactOverridesApp() {
        let presentedOverrides: PresentedOverrides<LocalizedTextPartial> = .init(
            app: .init(
                text: "override_id_app",
                partial: .init(
                    visible: nil,
                    fontWeight: .light,
                    fontSize: .bodyL
                )
            ),
            introOffer: nil,
            states: nil,
            conditions: .init(
                compact: .init(
                    text: "override_id_compact",
                    partial: .init(
                        visible: nil,
                        fontSize: .bodyM,
                        horizontalAlignment: .leading
                    )
                ),
                medium: .init(
                    text: "override_id_medium",
                    partial: .init(
                        visible: nil,
                        horizontalAlignment: .trailing
                    )
                ),
                expanded: nil
            )
        )

        let localizedPartial = LocalizedTextPartial.buildPartial(
            state: .default,
            condition: .medium,
            isEligibleForIntroOffer: false,
            with: presentedOverrides
        )

        let expectedResult = LocalizedTextPartial(
            text: "override_id_medium", // From medium
            partial: .init(
                visible: nil,
                fontWeight: .light, // From app
                fontSize: .bodyM, // From compact
                horizontalAlignment: .trailing // From medium
            )
        )

        expect(localizedPartial).to(equal(expectedResult))
    }

}

#endif
