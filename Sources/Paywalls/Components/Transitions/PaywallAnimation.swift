//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallAnimation.swift
//
//  Created by Jacob Zivan Rakidzich on 8/20/25.
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {
    struct Animation: PaywallComponentBase {
        public let type: AnimationType
        public let msDelay: Int?
        public let msDuration: Int?

        public init(from decoder: any Decoder) throws {
            let passthrough = try AnimationCodingContainer(from: decoder)

            self.type = AnimationType.from(passthrough.type) ?? .easeInOut
            self.msDelay = passthrough.msDelay
            self.msDuration = passthrough.msDuration
        }

        public func encode(to encoder: any Encoder) throws {
            try AnimationCodingContainer(type: type.codingContainer, msDelay: msDelay, msDuration: msDuration)
                .encode(to: encoder)
        }
    }

    internal struct AnimationCodingContainer: Codable {
        let type: AnimationTypeContainer
        let msDelay: Int?
        let msDuration: Int?
    }

    internal struct AnimationTypeContainer: Codable {
        let type: String
        let value: String?
    }

    enum AnimationType: Equatable, Hashable, Sendable {
        case bouncy
        case easeIn
        case easeInOut
        case easeOut
        case linear
        case smooth
        case snappy
        case spring
        case custom(String)

        var codingContainer: AnimationTypeContainer {
            let type: String
            var value: String?
            switch self {
            case .bouncy:
                type = "bouncy"
            case .easeIn:
                type = "easeIn"
            case .easeInOut:
                type = "easeInOut"
            case .easeOut:
                type = "easeOut"
            case .linear:
                type = "linear"
            case .smooth:
                type = "smooth"
            case .snappy:
                type = "snappy"
            case .spring:
                type = "spring"
            case .custom(let animation):
                type = "custom"
                value = animation
            }
            return AnimationTypeContainer(type: type, value: value)
        }

        // swiftlint:disable:next cyclomatic_complexity
        static func from(_ container: AnimationTypeContainer) -> AnimationType? {
            switch container.type {
            case "bouncy":
                .bouncy
            case "easeIn":
                .easeIn
            case "easeInOut":
                .easeInOut
            case "easeOut":
                .easeOut
            case "linear":
                .linear
            case "smooth":
                .smooth
            case "snappy":
                .snappy
            case "spring":
                .spring
            case "custom":
                if let value = container.value {
                    .custom(value)
                } else {
                    nil
                }
            default:
                nil
            }
        }

    }
}
