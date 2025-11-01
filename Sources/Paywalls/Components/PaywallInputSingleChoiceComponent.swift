//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallInputSingleChoiceComponent.swift
//
//  Created by AI Assistant
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class InputSingleChoiceComponent: PaywallComponentBase {

        let type: ComponentType
        public let visible: Bool?
        public let stack: PaywallComponent.StackComponent
        public let fieldId: String

        public init(
            visible: Bool? = nil,
            stack: PaywallComponent.StackComponent,
            fieldId: String
        ) {
            self.type = .inputSingleChoice
            self.visible = visible
            self.stack = stack
            self.fieldId = fieldId
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case visible
            case stack
            case fieldId = "fieldId"
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.visible = try container.decodeIfPresent(Bool.self, forKey: .visible)
            self.stack = try container.decode(PaywallComponent.StackComponent.self, forKey: .stack)
            self.fieldId = try container.decode(String.self, forKey: .fieldId)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(visible, forKey: .visible)
            try container.encode(stack, forKey: .stack)
            try container.encode(fieldId, forKey: .fieldId)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(stack)
            hasher.combine(fieldId)
        }

        public static func == (lhs: InputSingleChoiceComponent, rhs: InputSingleChoiceComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.stack == rhs.stack &&
                   lhs.fieldId == rhs.fieldId
        }
    }

    final class PartialInputSingleChoiceComponent: PaywallPartialComponent {

        public let visible: Bool?

        public init(
            visible: Bool? = true
        ) {
            self.visible = visible
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
        }

        public static func == (lhs: PartialInputSingleChoiceComponent, rhs: PartialInputSingleChoiceComponent) -> Bool {
            return lhs.visible == rhs.visible
        }
    }

}
