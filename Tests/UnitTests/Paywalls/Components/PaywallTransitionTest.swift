//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponent.TransitionTest.swift
//
//  Created by Jacob Zivan Rakidzich on 8/21/25.

@testable import RevenueCat
import XCTest

final class PaywallTransitionTest: TestCase {
    let arguments =  [
        (
            "EaseInOut, greedy, fade and scale",
            """
            {
             "animation": {
               "ms_delay": 1500,
               "ms_duration": 300,
               "type": "ease_in_out"
             },
             "displacement_strategy": "greedy",
             "type": "fade_and_scale"
            }
            """,
            PaywallComponent.Transition(
                type: PaywallComponent.TransitionType.fadeAndScale,
                displacementStrategy: PaywallComponent.DisplacementStrategy.greedy,
                animation: PaywallComponent.Animation(
                    type: PaywallComponent.AnimationType.easeInOut,
                    msDelay: 1500,
                    msDuration: 300
                )
            )
        ),
        (
            "no animation, lazy, fade",
            """
            {
             "displacement_strategy": "lazy",
             "type": "fade"
            }
            """,
            PaywallComponent.Transition(
                type: PaywallComponent.TransitionType.fade,
                displacementStrategy: PaywallComponent.DisplacementStrategy.lazy,
                animation: nil
            )
        ),
        (
            "Example custom animation and transition (not currently supported) fallsback to safe serialiization",
            """
            {
             "animation": {
               "ms_delay": 1500,
               "ms_duration": 300,
               "type": "custom"
             },
             "displacement_strategy": "greedy",
             "type": "custom"
            }
            """,
            PaywallComponent.Transition(
                type: PaywallComponent.TransitionType.fade,
                displacementStrategy: PaywallComponent.DisplacementStrategy.greedy,
                animation: PaywallComponent.Animation(
                    type: PaywallComponent.AnimationType.easeInOut,
                    msDelay: 1500,
                    msDuration: 300
                )
            )
        )
    ]

    func test_codable() async throws {
        for (title, json, transition) in arguments {
            let data = json.data(using: .utf8).unsafelyUnwrapped
            let decoded = try JSONDecoder.default.decode(PaywallComponent.Transition.self, from: data)
            XCTAssertEqual(decoded, transition, "\(title) Failed")

            let transition2 = try transition.encodeAndDecode()

            XCTAssertEqual(transition, transition2, "\(title) Failed")
        }
    }
}
