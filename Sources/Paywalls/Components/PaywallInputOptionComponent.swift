//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallInputOptionComponent.swift
//
//  Created by AI Assistant
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    struct InputOptionTriggers: PaywallComponentBase {
        public let onPress: String
    }

    final class InputOptionComponent: PaywallComponentBase {

        let type: ComponentType
        public let visible: Bool?
        public let stack: PaywallComponent.StackComponent
        public let optionId: String
        public let triggers: InputOptionTriggers?

        public init(
            visible: Bool? = nil,
            stack: PaywallComponent.StackComponent,
            optionId: String,
            triggers: InputOptionTriggers? = nil
        ) {
            self.type = .inputOption
            self.visible = visible
            self.stack = stack
            self.optionId = optionId
            self.triggers = triggers
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case visible
            case stack
            case optionId = "optionId"
            case triggers
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.visible = try container.decodeIfPresent(Bool.self, forKey: .visible)
            self.stack = try container.decode(PaywallComponent.StackComponent.self, forKey: .stack)
            self.optionId = try container.decode(String.self, forKey: .optionId)
            self.triggers = try container.decodeIfPresent(InputOptionTriggers.self, forKey: .triggers)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(visible, forKey: .visible)
            try container.encode(stack, forKey: .stack)
            try container.encode(optionId, forKey: .optionId)
            try container.encodeIfPresent(triggers, forKey: .triggers)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(stack)
            hasher.combine(optionId)
            hasher.combine(triggers)
        }

        public static func == (lhs: InputOptionComponent, rhs: InputOptionComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.stack == rhs.stack &&
                   lhs.optionId == rhs.optionId &&
                   lhs.triggers == rhs.triggers
        }
    }

    final class PartialInputOptionComponent: PaywallPartialComponent {

        public let visible: Bool?

        public init(
            visible: Bool? = true
        ) {
            self.visible = visible
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
        }

        public static func == (lhs: PartialInputOptionComponent, rhs: PartialInputOptionComponent) -> Bool {
            return lhs.visible == rhs.visible
        }
    }

}
