//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallHeaderComponent.swift
//
//  Created by OpenAI on 02/04/2026.
//
// swiftlint:disable missing_docs

import Foundation

@_spi(Internal) public extension PaywallComponent {

    private enum HeaderCodingKeys: String, CodingKey {
        case type
        case stack
    }

    private enum HeaderType: String, Codable {
        case header
    }

    final class HeaderComponent: PaywallComponentBase {

        @_spi(Internal) public let stack: PaywallComponent.StackComponent

        @_spi(Internal) public init(
            stack: PaywallComponent.StackComponent
        ) {
            self.stack = stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(stack)
        }

        public static func == (lhs: HeaderComponent, rhs: HeaderComponent) -> Bool {
            return lhs.stack == rhs.stack
        }

        @_spi(Internal) public convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: HeaderCodingKeys.self)
            let stack = try container.decode(PaywallComponent.StackComponent.self, forKey: .stack)

            self.init(stack: stack)
        }

        @_spi(Internal) public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: HeaderCodingKeys.self)

            try container.encode(HeaderType.header, forKey: .type)
            try container.encode(self.stack, forKey: .stack)
        }

    }

}
