//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs todo
import Foundation

#if PAYWALL_COMPONENTS
import SwiftUI // TODO: This feels wrong

public typealias TierId = String
public typealias LocaleId = String
public typealias ColorHex = String

public typealias DisplayString = PaywallComponent.LocaleResources<String>

protocol PaywallComponentBase: Codable, Sendable, Hashable, Equatable { }

public enum PaywallComponent: PaywallComponentBase {

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

    case text(TextComponent)
    case image(ImageComponent)
    case spacer(SpacerComponent)
    case stack(StackComponent)
    case linkButton(LinkButtonComponent)

    enum CodingKeys: String, CodingKey {

        case type

    }

    public enum ComponentType: String, Codable, Sendable {

        case text
        case image
        case spacer
        case stack
        case linkButton = "link_button"

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

public extension PaywallComponent {

    struct ColorInfo: Codable, Sendable, Hashable, Equatable {

        public init(light: ColorHex, dark: ColorHex? = nil) {
            self.light = light
            self.dark = dark
        }

        public let light: ColorHex
        public let dark: ColorHex?

    }

    struct LocaleResources<T: Codable & Sendable & Hashable & Equatable>: Codable, Sendable, Hashable, Equatable {

        public init(value: [LocaleId: T]) {
            self.value = value
        }

        public let value: [LocaleId: T]

    }

    struct Padding: Codable, Sendable, Hashable, Equatable {

        public init(top: Double, bottom: Double, leading: Double, trailing: Double) {
            self.top = top
            self.bottom = bottom
            self.leading = leading
            self.trailing = trailing
        }

        public let top: Double
        public let bottom: Double
        public let leading: Double
        public let trailing: Double

        public static let `default` = Padding(top: 10, bottom: 10, leading: 20, trailing: 20)
        public static let zero = Padding(top: 0, bottom: 0, leading: 0, trailing: 0)

    }

    struct Data: Sendable, Hashable, Equatable {

        public init(
            backgroundColor: ColorInfo,
            components: [PaywallComponent]
        ) {
            self.backgroundColor = backgroundColor
            self.components = components
        }

        public let backgroundColor: ColorInfo
        public let components: [PaywallComponent]

    }

    enum HorizontalAlignment: String, Codable, Sendable, Hashable, Equatable {

        case leading
        case center
        case trailing

        public var textAlignment: TextAlignment {
            switch self {
            case .leading:
                return .leading
            case .center:
                return .center
            case .trailing:
                return .trailing
            }
        }

        public var stackAlignment: SwiftUI.HorizontalAlignment {
            switch self {
            case .leading:
                return .leading
            case .center:
                return .center
            case .trailing:
                return .trailing
            }
        }

    }

    enum VerticalAlignment: String, Codable, Sendable, Hashable, Equatable {

        case top
        case center
        case bottom

        public var stackAlignment: SwiftUI.VerticalAlignment {
            switch self {
            case .top:
                return .top
            case .center:
                return .center
            case .bottom:
                return .bottom
            }
        }

    }

    enum TwoDimensionAlignment: String, Decodable, Sendable, Hashable, Equatable {

        case center
        case leading
        case trailing
        case top
        case bottom
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing

        public var stackAlignment: SwiftUI.Alignment {
            switch self {
            case .center:
                return .center
            case .leading:
                return .leading
            case .trailing:
                return .trailing
            case .top:
                return .top
            case .bottom:
                return .bottom
            case .topLeading:
                return .topLeading
            case .topTrailing:
                return .topTrailing
            case .bottomLeading:
                return .bottomLeading
            case .bottomTrailing:
                return .bottomTrailing
            }
        }

    }

    enum FontWeight: String, Codable, Sendable, Hashable, Equatable {

        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black

        public var fontWeight: Font.Weight {
            switch self {
            case .ultraLight:
                return .ultraLight
            case .thin:
                return .thin
            case .light:
                return .light
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .semibold:
                return .semibold
            case .bold:
                return .bold
            case .heavy:
                return .heavy
            case .black:
                return .black
            }
        }

    }

    enum TextStyle: String, Codable, Sendable, Hashable, Equatable {

        case largeTitle
        case title
        case title2
        case title3
        case headline
        case subheadline
        case body
        case callout
        case footnote
        case caption
        case caption2

        // Swift 5.9 stuff
        case extraLargeTitle
        case extraLargeTitle2

        public var font: Font {
            switch self {
            case .largeTitle: return .largeTitle
            case .title: return .title
            case .title2: if #available(iOS 14.0, *) {
                return .title2
            } else {
                return .title
            }
            case .title3: if #available(iOS 14.0, *) {
                return .title3
            } else {
                return .title
            }
            case .headline: return .headline
            case .subheadline: return .subheadline
            case .body: return .body
            case .callout: return .callout
            case .footnote: return .footnote
            case .caption: return .caption
            case .caption2: if #available(iOS 14.0, *) {
                return .caption2
            } else {
                return .caption
            }

            #if swift(>=5.9) && VISION_OS
            case .extraLargeTitle: return .extraLargeTitle
            case .extraLargeTitle2: return .extraLargeTitle2
            #else
            case .extraLargeTitle: return .largeTitle
            case .extraLargeTitle2: return .largeTitle
            #endif
            }
        }

    }

}

#endif
