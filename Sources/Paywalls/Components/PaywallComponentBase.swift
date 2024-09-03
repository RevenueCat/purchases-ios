//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs todo
import Foundation

#if PAYWALL_COMPONENTS

public typealias TierId = String
public typealias LocaleID = String
public typealias ColorHex = String
public typealias LocalizationDictionary = [String: String]
public typealias LocalizationKey = String

extension LocalizationDictionary {

    public func string<T: PaywallComponentBase>(from component: T, key keyPath: KeyPath<T, LocalizationKey?>) throws -> String {
        guard let stringID = component[keyPath: keyPath] else {
            let propertyName = "\(keyPath)"
            throw LocalizationValidationError.missingLocalization("Required localization ID for \(propertyName) is null.")
        }
        guard let value = self[stringID] else {
            let propertyName = "\(keyPath)"
            throw LocalizationValidationError.missingLocalization("Missing localization for property \(propertyName) with id: \"\(stringID)\"")
        }
        return value
    }
    
}

public typealias DisplayString = PaywallComponent.LocaleResources<String>

public protocol PaywallComponentBase: Codable, Sendable, Hashable, Equatable { }

enum LocalizationValidationError: Error {
    case missingLocalization(String)
}

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