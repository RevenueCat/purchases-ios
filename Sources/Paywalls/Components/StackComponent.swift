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

        public enum Dimension: String, Codable, Sendable, Hashable {
            case vertical
            case horizontal
            case zlayer
        }

        let type: String
        public let components: [PaywallComponent]
//        let alignment: HorizontalAlignment?
        public let spacing: CGFloat?
        public let backgroundColor: String?
        public var backgroundPaywallColor: PaywallColor? {
            backgroundColor.flatMap { try? PaywallColor(stringRepresentation: $0) }
        }
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

        public init(components: [PaywallComponent], dimension: Dimension = .vertical, spacing: CGFloat?, backgroundColor: String?) {
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
