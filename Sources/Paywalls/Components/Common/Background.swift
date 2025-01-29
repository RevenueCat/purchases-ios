//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Background.swift
//
//  Created by Josh Holtz on 11/20/24.
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {

    enum Background: Codable, Sendable, Hashable {

        case color(ColorScheme)
        case image(ThemeImageUrls)

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .color(let colorScheme):
                try container.encode(BackgroundType.color.rawValue, forKey: .type)
                try container.encode(colorScheme, forKey: .value)
            case .image(let imageInfo):
                try container.encode(BackgroundType.image.rawValue, forKey: .type)
                try container.encode(imageInfo, forKey: .value)

            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(BackgroundType.self, forKey: .type)

            switch type {
            case .color:
                let value = try container.decode(ColorScheme.self, forKey: .value)
                self = .color(value)
            case .image:
                let value = try container.decode(ThemeImageUrls.self, forKey: .value)
                self = .image(value)
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case value

        }

        // swiftlint:disable:next nesting
        private enum BackgroundType: String, Decodable {

            case color
            case image

        }

    }

}
