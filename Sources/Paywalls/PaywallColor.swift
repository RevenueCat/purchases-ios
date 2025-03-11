//
//  PaywallColor.swift
//  
//
//  Created by Nacho Soto on 7/14/23.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif

// swiftlint:disable redundant_string_enum_value

/// Represents a color to be used by `RevenueCatUI`
public struct PaywallColor {

    /// The possible color schemes, corresponding to the light and dark appearances.
    @frozen
    public enum ColorScheme: String {

        /// The color scheme that corresponds to a light appearance.
        case light = "light"
        /// The color scheme that corresponds to a dark appearance.
        case dark = "dark"

    }

    /// The original Hex representation for this color.
    public var stringRepresentation: String

    #if canImport(SwiftUI)
    /// The underlying SwiftUI `Color`.
    public var underlyingColor: Color {
        // swiftlint:disable:next force_cast
        return self._underlyingColor as! Color
    }
    #endif

    // Only available from iOS 13
    fileprivate var _underlyingColor: (any Sendable)?

}

// MARK: - Public constructors

extension PaywallColor {

    #if canImport(SwiftUI)

    /// Creates a color from a Hex string: `#RRGGBB` or `#RRGGBBAA`.
    public init(stringRepresentation: String) throws {
        self.init(stringRepresentation: stringRepresentation, color: try Self.parseColor(stringRepresentation))
    }

        #if canImport(UIKit)

        /// Creates a dynamic color for 2 ``ColorScheme``s.
        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        public init(light: PaywallColor, dark: PaywallColor) {
            self.init(stringRepresentation: light.stringRepresentation,
                      color: .init(light: light.underlyingColor, dark: dark.underlyingColor))
        }

        #endif

    #endif

}

// MARK: - Private constructors

private extension PaywallColor {

    #if canImport(SwiftUI)

    init(stringRepresentation: String, color: Color) {
        self.init(stringRepresentation: stringRepresentation, underlyingColor: color)
    }

    static func parseColor(_ input: String) throws -> Color {
        let red, green, blue, alpha: CGFloat

        guard input.hasPrefix("#") else {
            throw Error.invalidStringFormat(input)
        }

        let start = input.index(input.startIndex, offsetBy: 1)
        let hexColor = String(input[start...])

        guard hexColor.count == 6 || hexColor.count == 8 else {
            throw Error.invalidStringFormat(input)
        }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            // If Alpha channel is missing, it's a fully opaque color.
            if hexColor.count == 6 {
                hexNumber <<= 8
                hexNumber |= 0xff
            }

            red = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            green = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            blue = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            alpha = CGFloat(hexNumber & 0x000000ff) / 255

            return .init(red: red, green: green, blue: blue, opacity: alpha)
        } else {
            throw Error.invalidColor(input)
        }
    }

    #endif

    /// "Designated" initializer
    private init(stringRepresentation: String, underlyingColor: (any Sendable)?) {
        self.stringRepresentation = stringRepresentation
        self._underlyingColor = underlyingColor
    }

}

// MARK: - Errors

private extension PaywallColor {

    enum Error: Swift.Error {

        case invalidStringFormat(String)
        case invalidColor(String)

    }

}

// MARK: - Extensions

#if canImport(UIKit)
private extension UIColor {

    @available(iOS 13.0, tvOS 13.0, macCatalyst 13.1, macOS 10.15, watchOS 6.2, *)
    convenience init(light: UIColor, dark: UIColor) {
        #if os(watchOS)
        self.init(cgColor: dark.cgColor)
        #else
        self.init { trait in
            switch trait.userInterfaceStyle {
            case .dark:
                return dark
            case .light, .unspecified:
                fallthrough
            @unknown default:
                return light
            }
        }
        #endif
    }

}
#endif

#if canImport(SwiftUI)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public extension Color {

    /// Converts a `Color` into a `PaywallColor`.
    var asPaywallColor: PaywallColor {
        return .init(stringRepresentation: self.stringRepresentation,
                     color: self)
    }

}

#if canImport(UIKit)

    private extension Color {

        init(light: UIColor, dark: UIColor) {
            self.init(UIColor(light: light, dark: dark))
        }

        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        init(light: Color, dark: Color) {
            self.init(light: UIColor(light), dark: UIColor(dark))
        }

    }

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension UIColor {

    /// Converts a `UIColor` into a `PaywallColor`.
    var asPaywallColor: PaywallColor {
        return Color(uiColor: self).asPaywallColor
    }

}

#elseif os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension NSColor {

    /// Converts an `NSColor` into a `PaywallColor`.
    var asPaywallColor: PaywallColor {
        return Color(nsColor: self).asPaywallColor
    }

}

#endif

#endif

// MARK: - Conformances

// swiftlint:disable missing_docs

extension PaywallColor.ColorScheme: Equatable {}
extension PaywallColor.ColorScheme: Sendable {}
extension PaywallColor.ColorScheme: Codable {}

extension PaywallColor: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "\(type(of: self)): \(self.stringRepresentation)"
    }

}

extension PaywallColor: Equatable {

    public static func == (lhs: PaywallColor, rhs: PaywallColor) -> Bool {
        return lhs.stringRepresentation == rhs.stringRepresentation
    }

}

extension PaywallColor: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.stringRepresentation)
    }

}

extension PaywallColor: Sendable {}
extension PaywallColor: Codable {

    public init(from decoder: Decoder) throws {
        try self.init(stringRepresentation: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container .encode(self.stringRepresentation)
    }

}

// swiftlint:enable missing_docs

// MARK: -

#if canImport(SwiftUI) && canImport(UIKit)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
internal extension Color {

    var rgba: (red: Int, green: Int, blue: Int, alpha: Int) {
        let color = UIColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        assert(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))

        return (red.rounded, green.rounded, blue.rounded, alpha.rounded)
    }

}

#elseif os(macOS)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
internal extension Color {

    var rgba: (red: Int, green: Int, blue: Int, alpha: Int) {
        let color = NSColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red.rounded, green.rounded, blue.rounded, alpha.rounded)
    }

}

#endif

#if canImport(SwiftUI)

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private extension Color {

    /// - Returns: the color converted to `#RRGGBBAA` or `#RRGGBB`.`
    var stringRepresentation: String {
        let (red, green, blue, alpha) = self.rgba

        if alpha < 255 {
            return String(format: "#%02X%02X%02X%02X", red, green, blue, alpha)
        } else {
            return String(format: "#%02X%02X%02X", red, green, blue)
        }
    }

}

#endif

private extension CGFloat {

    var rounded: Int {
        return Int((self * 255).rounded())
    }

}
