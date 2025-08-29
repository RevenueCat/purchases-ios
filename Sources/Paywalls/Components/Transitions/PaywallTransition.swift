//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallTransition.swift
//
//  Created by Jacob Zivan Rakidzich on 8/20/25.
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {

    struct Transition: PaywallComponentBase {

        public let type: TransitionType
        public let displacementStrategy: DisplacementStrategy
        public let animation: PaywallComponent.Animation?

        init (
            type: TransitionType = .fade,
            displacementStrategy: DisplacementStrategy = .greedy,
            animation: PaywallComponent.Animation? = nil
        ) {
            self.type = type
            self.displacementStrategy = displacementStrategy
            self.animation = animation
        }
    }

    ///
    /// Determines how the view being animated out is displaced by the view being animated in.
    ///
    /// A `greedy` displacement will result in the space being taken up by the incoming view
    /// *before* it attempts to transition into the view hierarchy.
    ///
    /// A `lazy` displacement will not do this, instead it will result in shifting the layout
    /// as the new view inserts itself.
    ///
    enum DisplacementStrategy: String, PaywallComponentBase {
        case greedy, lazy
    }

    /// Defines the type of transition to use for paywall transitions.
    enum TransitionType: String, PaywallComponentBase {

        case fade
        case fadeAndScale = "fade_and_scale"
        case scale
        case slide

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try? container.decode(String.self)
            self = TransitionType(rawValue: rawValue ?? "") ?? .fade
        }

    }

}
