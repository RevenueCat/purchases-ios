//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable all

import Foundation
import SwiftUI // TODO: This feels wrong

#if PAYWALL_COMPONENTS

public typealias TierId = String
public typealias LocaleId = String
public typealias ColorHex = String

public typealias DisplayString = PaywallComponent.LocaleResources<String>
public typealias FocusIdentifier = String

protocol PaywallComponentBase: Decodable, Sendable, Hashable, Equatable {
    var displayPreferences: [DisplayPreference]? { get }

    var focusIdentifiers: [FocusIdentifier]? { get }
}

public enum PaywallComponent: Decodable, Sendable, Hashable, Equatable {
    public static func == (lhs: PaywallComponent, rhs: PaywallComponent) -> Bool {
        return false // TODO: Fix
    }

    case tiers(TiersComponent)
    case tierSelector(TierSelectorComponent)
    case tierToggle(TierToggleComponent)
    case text(TextComponent)
    case image(ImageComponent)
    case spacer(SpacerComponent)
    case stack(StackComponent)
    case linkButton(LinkButtonComponent)

    enum CodingKeys: String, CodingKey {
        case type
    }

    enum ComponentType: String, Codable {
        case tiers
        case tierSelector
        case tierToggle
        case text
        case image
        case spacer
        case stack
        case linkButton
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ComponentType.self, forKey: .type)

        switch type {
        case .tiers:
            self = .tiers(try TiersComponent(from: decoder))
        case .tierSelector:
            self = .tierSelector(try TierSelectorComponent(from: decoder))
        case .tierToggle:
            self = .tierToggle(try TierToggleComponent(from: decoder))
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

    public var displayPreferences: [DisplayPreference]? {
        switch self {
        case .tiers(let component):
            return component.displayPreferences
        case .tierSelector(let component):
            return component.displayPreferences
        case .tierToggle(let component):
            return component.displayPreferences
        case .text(let component):
            return component.displayPreferences
        case .image(let component):
            return component.displayPreferences
        case .spacer(let component):
            return component.displayPreferences
        case .stack(let component):
            return component.displayPreferences
        case .linkButton(let component):
            return component.displayPreferences
        }
    }

    public var focusIdentifier: [FocusIdentifier]? {
        switch self {
        case .tiers(let component):
            return component.focusIdentifiers
        case .tierSelector(let component):
            return component.focusIdentifiers
        case .tierToggle(let component):
            return component.focusIdentifiers
        case .text(let component):
            return component.focusIdentifiers
        case .image(let component):
            return component.focusIdentifiers
        case .spacer(let component):
            return component.focusIdentifiers
        case .stack(let component):
            return component.focusIdentifiers
        case .linkButton(let component):
            return component.focusIdentifiers
        }
    }
}

public enum DisplayPreference: String, Decodable, Sendable, Hashable, Equatable {
    case landscapeLeft, landscapeRight, portrait
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

    struct TierResources<T: Codable & Sendable & Hashable & Equatable>: Codable, Sendable, Hashable, Equatable {
        public init(value: [TierId : T]) {
            self.value = value
        }
        
        public let value: [TierId: T]
    }

    struct LocaleResources<T: Codable & Sendable & Hashable & Equatable>: Codable, Sendable, Hashable, Equatable {
        public init(value: [LocaleId : T]) {
            self.value = value
        }
        
        public let value: [LocaleId: T]
    }

    struct Packages: Codable, Sendable, Hashable, Equatable {
        public init(`default`: PaywallComponent.Packages.Package, packages: [PaywallComponent.Packages.Package]) {
            self.`default` = `default`
            self.packages = packages
        }
        
        public let `default`: Package
        public let packages: [Package]

        public struct Package: Codable, Sendable, Hashable, Equatable, Identifiable {
            public var id: String {
                return self.packageId
            }

            public init(
                packageId: String,
                name: PaywallComponent.LocaleResources<String>,
                details: PaywallComponent.LocaleResources<String>,
                detailsIntroOffer: PaywallComponent.LocaleResources<String>
            ) {
                self.packageId = packageId
                self.name = name
                self.details = details
                self.detailsIntroOffer = detailsIntroOffer
            }
            
            let packageId: String
            let name: LocaleResources<String>
            let details: LocaleResources<String>
            let detailsIntroOffer: LocaleResources<String>
        }
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
    
    enum HorizontalAlignment: String, Decodable, Sendable, Hashable, Equatable {
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

    enum VerticalAlignment: String, Decodable, Sendable, Hashable, Equatable {
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

    enum FontWeight: String, Decodable, Sendable, Hashable, Equatable {
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

    enum TextStyle: String, Decodable, Sendable, Hashable, Equatable {
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

            #if swift(>=5.9) && os(visionOS)
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
