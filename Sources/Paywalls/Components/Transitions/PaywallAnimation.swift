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

        init(type: AnimationType, msDelay: Int?, msDuration: Int?) {
            self.type = type
            self.msDelay = msDelay
            self.msDuration = msDuration
        }

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
        case easeIn
        case easeInOut
        case easeOut
        case linear
        case custom(String)

        var codingContainer: AnimationTypeContainer {
            let type: String
            var value: String?
            switch self {
            case .easeIn:
                type = "ease_in"
            case .easeInOut:
                type = "ease_in_out"
            case .easeOut:
                type = "ease_out"
            case .linear:
                type = "linear"
            case .custom(let animation):
                type = "custom"
                value = animation
            }
            return AnimationTypeContainer(type: type, value: value)
        }

        static func from(_ container: AnimationTypeContainer) -> AnimationType? {
            switch container.type {
            case "ease_in":
                return .easeIn
            case "ease_in_out":
                return .easeInOut
            case "ease_out":
                return .easeOut
            case "linear":
                return .linear
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
