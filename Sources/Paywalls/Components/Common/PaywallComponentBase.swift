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
    case button(ButtonComponent)
    case package(PackageComponent)
    case purchaseButton(PurchaseButtonComponent)
    case stickyFooter(StickyFooterComponent)

    public enum ComponentType: String, Codable, Sendable {

        case text
        case image
        case spacer
        case stack
        case linkButton = "link_button"
        case button
        case package
        case purchaseButton = "purchase_button"
        case stickyFooter = "sticky_footer"

    }

}

public extension PaywallComponent {
    typealias LocaleID = String
    typealias LocalizationDictionary = [String: PaywallComponentsData.LocalizationData]
    typealias LocalizationKey = String
    typealias ColorHex = String
}

extension PaywallComponent: Codable {

    enum CodingKeys: String, CodingKey {

        case type
        case fallback

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
        case .button(let component):
            try container.encode(ComponentType.button, forKey: .type)
            try component.encode(to: encoder)
        case .package(let component):
            try container.encode(ComponentType.package, forKey: .type)
            try component.encode(to: encoder)
        case .purchaseButton(let component):
            try container.encode(ComponentType.purchaseButton, forKey: .type)
            try component.encode(to: encoder)
        case .stickyFooter(let component):
            try container.encode(ComponentType.stickyFooter, forKey: .type)
            try component.encode(to: encoder)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode the raw string for the `type` field
        let typeString = try container.decode(String.self, forKey: .type)

        // Attempt to convert raw string into our `ComponentType` enum
        if let type = ComponentType(rawValue: typeString) {
            self = try Self.decodeType(from: decoder, type: type)
        } else {
            if !container.contains(.fallback) {
                let context = DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                      """
                      Failed to decode unknown type "\(typeString)" without a fallback.
                      """
                )
                throw DecodingError.dataCorrupted(context)
            }

            do {
                // If `typeString` is unknown, try to decode the fallback
                self = try container.decode(PaywallComponent.self, forKey: .fallback)
            } catch DecodingError.valueNotFound {
                let context = DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                      """
                      Failed to decode unknown type "\(typeString)" without a fallback.
                      """
                )
                throw DecodingError.dataCorrupted(context)
            } catch {
                let context = DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                      """
                      Failed to decode fallback for unknown type "\(typeString)".
                      """,
                    underlyingError: error
                )
                throw DecodingError.dataCorrupted(context)
            }
        }
    }

    private static func decodeType(from decoder: Decoder, type: ComponentType) throws -> PaywallComponent {
        switch type {
        case .text:
            return .text(try TextComponent(from: decoder))
        case .image:
            return .image(try ImageComponent(from: decoder))
        case .spacer:
            return .spacer(try SpacerComponent(from: decoder))
        case .stack:
            return .stack(try StackComponent(from: decoder))
        case .linkButton:
            return .linkButton(try LinkButtonComponent(from: decoder))
        case .button:
            return .button(try ButtonComponent(from: decoder))
        case .package:
            return .package(try PackageComponent(from: decoder))
        case .purchaseButton:
            return .purchaseButton(try PurchaseButtonComponent(from: decoder))
        case .stickyFooter:
            return .stickyFooter(try StickyFooterComponent(from: decoder))
        }
    }

}

#endif
