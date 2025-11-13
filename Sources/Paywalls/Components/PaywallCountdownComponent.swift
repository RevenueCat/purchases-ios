//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallCountdownComponent.swift
//
//  Created by Josh Holtz on 1/14/25.
//
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class CountdownComponent: PaywallComponentBase {

        let type: ComponentType
        public let name: String?
        public let style: CountdownStyle
        public let countdownStack: PaywallComponent.StackComponent
        public let endStack: PaywallComponent.StackComponent?
        public let fallback: PaywallComponent.StackComponent?
        public let overrides: ComponentOverrides<PartialCountdownComponent>?

        public init(
            id: String? = nil,
            name: String? = nil,
            style: CountdownStyle,
            countdownStack: PaywallComponent.StackComponent,
            endStack: PaywallComponent.StackComponent? = nil,
            fallback: PaywallComponent.StackComponent? = nil,
            overrides: ComponentOverrides<PartialCountdownComponent>? = nil
        ) {
            self.type = .countdown
            self.name = name
            self.style = style
            self.countdownStack = countdownStack
            self.endStack = endStack
            self.fallback = fallback
            self.overrides = overrides
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case name
            case style
            case countdownStack = "countdownStack"
            case endStack = "endStack"
            case fallback
            case overrides
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.style = try container.decode(CountdownStyle.self, forKey: .style)
            self.countdownStack = try container.decode(PaywallComponent.StackComponent.self, forKey: .countdownStack)
            self.endStack = try container.decodeIfPresent(PaywallComponent.StackComponent.self, forKey: .endStack)
            self.fallback = try container.decodeIfPresent(PaywallComponent.StackComponent.self, forKey: .fallback)
            self.overrides = try container.decodeIfPresent(
                ComponentOverrides<PartialCountdownComponent>.self,
                forKey: .overrides
            )
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encode(style, forKey: .style)
            try container.encode(countdownStack, forKey: .countdownStack)
            try container.encode(endStack, forKey: .endStack)
            try container.encode(fallback, forKey: .fallback)
            try container.encode(overrides, forKey: .overrides)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(name)
            hasher.combine(style)
            hasher.combine(countdownStack)
            hasher.combine(endStack)
            hasher.combine(fallback)
            hasher.combine(overrides)
        }

        public static func == (lhs: CountdownComponent, rhs: CountdownComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.name == rhs.name &&
                   lhs.style == rhs.style &&
                   lhs.countdownStack == rhs.countdownStack &&
                   lhs.endStack == rhs.endStack &&
                   lhs.fallback == rhs.fallback &&
                   lhs.overrides == rhs.overrides
        }

        public struct CountdownStyle: Codable, Sendable, Hashable, Equatable {
            public let type: String
            public let date: Date

            public init(type: String = "date", date: Date) {
                self.type = type
                self.date = date
            }
        }
    }

    final class PartialCountdownComponent: PaywallPartialComponent {
        public let style: CountdownComponent.CountdownStyle?

        public init(style: CountdownComponent.CountdownStyle? = nil) {
            self.style = style
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(style)
        }

        public static func == (lhs: PartialCountdownComponent, rhs: PartialCountdownComponent) -> Bool {
            return lhs.style == rhs.style
        }
    }

}
