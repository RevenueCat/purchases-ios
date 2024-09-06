//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs
import Foundation

#if PAYWALL_COMPONENTS

public protocol PaywallComponentBase: Codable, Sendable, Hashable, Equatable { }

public enum PaywallComponent: PaywallComponentBase {

    case text(TextComponent)
    case image(ImageComponent)
    case spacer(SpacerComponent)
    case stack(StackComponent)
    case linkButton(LinkButtonComponent)

    public enum ComponentType: String, Codable, Sendable {

        case text
        case image
        case spacer
        case stack
        case linkButton = "link_button"

    }

}

public extension PaywallComponent {
    typealias LocaleID = String
    typealias LocalizationDictionary = [String: String]
    typealias LocalizationKey = String
    typealias ColorHex = String
}

extension PaywallComponent: Codable {

    enum CodingKeys: String, CodingKey {

        case type

    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let component):
            try container.encode(ComponentType.text, forKey: .type)
            try component.encode(to: encoder)
        case .image(let component):
            try container.encode(ComponentType.image, forKey: .type)
            try component.encode(to: encoder)
        case .spacer(let component):
            try container.encode(ComponentType.spacer, forKey: .type)
            try component.encode(to: encoder)
        case .stack(let component):
            try container.encode(ComponentType.stack, forKey: .type)
            try component.encode(to: encoder)
        case .linkButton(let component):
            try container.encode(ComponentType.linkButton, forKey: .type)
            try component.encode(to: encoder)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ComponentType.self, forKey: .type)

        switch type {
        case .text:
            self = .text(try TextComponent(from: decoder))
        case .image:
            self = .image(try ImageComponent(from: decoder))
        case .spacer:
            self = .spacer(try SpacerComponent(from: decoder))
        case .stack:
            self = .stack(try StackComponent(from: decoder))
        case .linkButton:
            self = .linkButton(try LinkButtonComponent(from: decoder))
        }
    }

}

#endif
