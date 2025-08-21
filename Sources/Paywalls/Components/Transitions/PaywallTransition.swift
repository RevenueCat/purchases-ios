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

        public init(from decoder: any Decoder) throws {
            let passthrough = try TransitionCodingContainer(from: decoder)

            self.type = TransitionType.from(passthrough.type) ?? .fade
            self.displacementStrategy = passthrough.displacementStrategy
            self.animation = passthrough.animation
        }

        public func encode(to encoder: any Encoder) throws {
            try TransitionCodingContainer(
                type: type.codingContainer,
                displacementStrategy: displacementStrategy,
                animation: animation
            )
            .encode(to: encoder)
        }
    }

    internal struct TransitionCodingContainer: Codable {
        let type: TransitionTypeContainer
        let displacementStrategy: DisplacementStrategy
        let animation: PaywallComponent.Animation?
    }

    internal struct TransitionTypeContainer: Codable {
        let type: String
        let value: String?
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

    enum TransitionType: PaywallComponentBase {
        case fade
        case fadeAndScale
        case scale
        case slide
        case custom(String)

        var codingContainer: TransitionTypeContainer {
            let type: String
            var value: String?
            switch self {
            case .fade:
                type = "fade"
            case .fadeAndScale:
                type = "fadeAndScale"
            case .scale:
                type = "scale"
            case .slide:
                type = "slide"
            case .custom(let transition):
                type = "custom"
                value = transition
            }
            return TransitionTypeContainer(type: type, value: value)
        }

        static func from(_ container: TransitionTypeContainer) -> TransitionType? {
            switch container.type {
            case "fade":
                return .fade
            case "fadeAndScale":
                return .fadeAndScale
            case "scale":
                return .scale
            case "slide":
                return .slide
            case "custom":
                if let value = container.value {
                    return .custom(value)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }

    }
}
