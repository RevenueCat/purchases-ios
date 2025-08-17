//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallButtonComponent.swift
//
//  Created by Jay Shortway on 02/10/2024.
//
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class SlotLottieComponent: PaywallComponentBase {

        let type: ComponentType

        public let visible: Bool?
        public let value: Value
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?

        public let overrides: ComponentOverrides<PartialSlotLottieComponent>?

        public init(
            visible: Bool? = nil,
            identifier: String,
            value: Value,
            size: PaywallComponent.Size? = nil,
            padding: PaywallComponent.Padding? = .zero,
            margin: PaywallComponent.Padding? = .zero,
            overrides: ComponentOverrides<PartialSlotLottieComponent>? = nil
        ) {
            self.type = .slotLottie
            self.visible = visible
            self.value = value
            self.size = size
            self.padding = padding
            self.margin = margin
            self.overrides = overrides
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(value)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(overrides)
        }

        public static func == (lhs: SlotLottieComponent, rhs: SlotLottieComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.value == rhs.value &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.overrides == rhs.overrides
        }

        public enum Value: Codable, Sendable, Hashable, Equatable {
            case url(URL)

            case unknown

            private enum CodingKeys: String, CodingKey {
                case type
                case url
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                switch self {
                case .url:
                    try container.encode("restore_purchases", forKey: .type)
                case .unknown:
                    try container.encode("unknown", forKey: .type)
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let type = try container.decode(String.self, forKey: .type)

                switch type {
                case "url":
                    let url = try container.decode(URL.self, forKey: .url)
                    self = .url(url)
                case "unknown":
                    self = .unknown
                default:
                    self = .unknown
                }
            }
        }

    }

    final class PartialSlotLottieComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let value: SlotLottieComponent.Value?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?

        public init(
            visible: Bool? = true,
            value: SlotLottieComponent.Value? = nil,
            size: Size? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
        ) {
            self.visible = visible
            self.value = value
            self.size = size
            self.padding = padding
            self.margin = margin
        }

        private enum CodingKeys: String, CodingKey {
            case visible
            case value
            case size
            case padding
            case margin
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(value)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
        }

        public static func == (lhs: PartialSlotLottieComponent, rhs: PartialSlotLottieComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.value == rhs.value &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin
        }
    }

}
