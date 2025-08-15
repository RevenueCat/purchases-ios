//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs
import Foundation

public protocol PaywallComponentBase: Codable, Sendable, Hashable, Equatable {}

public enum PaywallComponent: Codable, Sendable, Hashable, Equatable {

    case text(TextComponent)
    case image(ImageComponent)
    case icon(IconComponent)
    case stack(StackComponent)
    case button(ButtonComponent)
    case package(PackageComponent)
    case purchaseButton(PurchaseButtonComponent)
    case stickyFooter(StickyFooterComponent)
    case timeline(TimelineComponent)

    case tabs(TabsComponent)
    case tabControl(TabControlComponent)
    case tabControlButton(TabControlButtonComponent)
    case tabControlToggle(TabControlToggleComponent)

    case carousel(CarouselComponent)

    public enum ComponentType: String, Codable, Sendable {

        case text
        case image
        case icon
        case stack
        case button
        case package
        case purchaseButton = "purchase_button"
        case stickyFooter = "sticky_footer"
        case timeline

        case tabs
        case tabControl = "tab_control"
        case tabControlButton = "tab_control_button"
        case tabControlToggle = "tab_control_toggle"

        case carousel

    }

}

public extension PaywallComponent {
    typealias LocaleID = String
    typealias LocalizationDictionary = [String: PaywallComponentsData.LocalizationData]
    typealias LocalizationKey = String
    typealias ColorHex = String
}

extension PaywallComponent {

    enum CodingKeys: String, CodingKey {

        case type
        case fallback

    }

    // swiftlint:disable:next cyclomatic_complexity
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let component):
            try container.encode(ComponentType.text, forKey: .type)
            try component.encode(to: encoder)
        case .image(let component):
            try container.encode(ComponentType.image, forKey: .type)
            try component.encode(to: encoder)
        case .icon(let component):
            try container.encode(ComponentType.icon, forKey: .type)
            try component.encode(to: encoder)
        case .stack(let component):
            try container.encode(ComponentType.stack, forKey: .type)
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
        case .timeline(let component):
            try container.encode(ComponentType.timeline, forKey: .type)
            try component.encode(to: encoder)
        case .tabs(let component):
            try container.encode(ComponentType.tabs, forKey: .type)
            try component.encode(to: encoder)
        case .tabControl(let component):
            try container.encode(ComponentType.tabControl, forKey: .type)
            try component.encode(to: encoder)
        case .tabControlButton(let component):
            try container.encode(ComponentType.tabControlButton, forKey: .type)
            try component.encode(to: encoder)
        case .tabControlToggle(let component):
            try container.encode(ComponentType.tabControlToggle, forKey: .type)
            try component.encode(to: encoder)
        case .carousel(let component):
            try container.encode(ComponentType.carousel, forKey: .type)
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

    // swiftlint:disable:next cyclomatic_complexity
    private static func decodeType(from decoder: Decoder, type: ComponentType) throws -> PaywallComponent {
        switch type {
        case .text:
            return .text(try TextComponent(from: decoder))
        case .image:
            return .image(try ImageComponent(from: decoder))
        case .icon:
            return .icon(try IconComponent(from: decoder))
        case .stack:
            return .stack(try StackComponent(from: decoder))
        case .button:
            return .button(try ButtonComponent(from: decoder))
        case .package:
            return .package(try PackageComponent(from: decoder))
        case .purchaseButton:
            return .purchaseButton(try PurchaseButtonComponent(from: decoder))
        case .stickyFooter:
            return .stickyFooter(try StickyFooterComponent(from: decoder))
        case .timeline:
            return .timeline(try TimelineComponent(from: decoder))
        case .tabs:
            return .tabs(try TabsComponent(from: decoder))
        case .tabControl:
            return .tabControl(try TabControlComponent(from: decoder))
        case .tabControlButton:
            return .tabControlButton(try TabControlButtonComponent(from: decoder))
        case .tabControlToggle:
            return .tabControlToggle(try TabControlToggleComponent(from: decoder))
        case .carousel:
            return .carousel(try CarouselComponent(from: decoder))
        }
    }

}
