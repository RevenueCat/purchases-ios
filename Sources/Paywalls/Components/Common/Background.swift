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
        case image(ThemeImageUrls, FitMode, ColorScheme?)
        case video(ThemeVideoUrls, ThemeImageUrls, Loop, MuteAudio, FitMode, ColorScheme?)

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .color(let colorScheme):
                try container.encode(BackgroundType.color.rawValue, forKey: .type)
                try container.encode(colorScheme, forKey: .value)
            case .image(let imageInfo, let fitMode, let colorScheme):
                try container.encode(BackgroundType.image.rawValue, forKey: .type)
                try container.encode(imageInfo, forKey: .value)
                try container.encode(fitMode, forKey: .fitMode)
                try container.encodeIfPresent(colorScheme, forKey: .colorOverlay)
            case let .video(videoInfo, imageInfo, loop, mute, fitMode, colorScheme):
                try container.encode(BackgroundType.video.rawValue, forKey: .type)
                try container.encode(videoInfo, forKey: .value)
                try container.encode(imageInfo, forKey: .fallbackImage)
                try container.encode(loop, forKey: .loop)
                try container.encode(mute, forKey: .muteAudio)
                try container.encode(fitMode, forKey: .fitMode)
                try container.encodeIfPresent(colorScheme, forKey: .colorOverlay)
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
                let fitMode = try container.decode(FitMode.self, forKey: .fitMode)
                let colorScheme = try container.decodeIfPresent(ColorScheme.self, forKey: .colorOverlay)
                self = .image(value, fitMode, colorScheme)
            case .video:
                let value = try container.decode(ThemeVideoUrls.self, forKey: .value)
                let image = try container.decode(ThemeImageUrls.self, forKey: .fallbackImage)
                let fitMode = try container.decode(FitMode.self, forKey: .fitMode)
                let loop = try container.decode(Loop.self, forKey: .loop)
                let mute = try container.decode(MuteAudio.self, forKey: .muteAudio)
                let colorScheme = try container.decodeIfPresent(ColorScheme.self, forKey: .colorOverlay)
                self = .video(value, image, loop, mute, fitMode, colorScheme)
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case value
            case fallbackImage
            case muteAudio
            case loop
            case fitMode
            case colorOverlay

        }

        // swiftlint:disable:next nesting
        private enum BackgroundType: String, Decodable {

            case color
            case image
            case video

        }

    }

}

public extension PaywallComponent.Background {
    typealias Loop = Bool
    typealias MuteAudio = Bool
}
