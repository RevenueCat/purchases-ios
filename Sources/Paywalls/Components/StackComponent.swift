//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponent.swift
//
//  Created by James Borthwick on 2024-08-20.

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct StackComponent: PaywallComponentBase {

        public enum Dimension: Codable, Sendable, Hashable {
            case vertical(HorizontalAlignment)
            case horizontal(VerticalAlignment)
            case zlayer

            public func encode(to encoder: Encoder) throws {
                //TODO
                fatalError()
            }

            public init(from decoder: Decoder) throws {
                // TODO
                fatalError()
            }


            public static func horizontal() -> Dimension {
                return .horizontal(.center)
            }

            public static func vertical() -> Dimension {
                return .vertical(.center)
            }
        }

        let type: String
        public let components: [PaywallComponent]
//        let alignment: HorizontalAlignment?
        public let spacing: CGFloat?
        public let backgroundColor: ColorInfo?
        public let dimension: Dimension
        let displayPreferences: [DisplayPreference]?
        var focusIdentifiers: [FocusIdentifier]?

        enum CodingKeys: String, CodingKey {
            case components
//            case alignment
            case spacing
            case backgroundColor
            case focusIdentifiers
            case displayPreferences
            case type
            case dimension
        }

        public init(components: [PaywallComponent], dimension: Dimension = .vertical(.center), spacing: CGFloat?, backgroundColor: ColorInfo?) {
            self.components = components
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.displayPreferences = nil
            self.focusIdentifiers = nil
            self.type = "stack"
            self.dimension = dimension
        }
    }
}

#endif
