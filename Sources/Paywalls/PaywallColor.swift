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

    // `Color` is not `Sendable` in Xcode 13.
    #if canImport(SwiftUI) && swift(>=5.7)
    /// The underlying SwiftUI `Color`.
    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
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

    #if canImport(SwiftUI) && swift(>=5.7)

    /// Creates a color from a Hex string: `#RRGGBB` or `#RRGGBBAA`.
    public init(stringRepresentation: String) throws {
        if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) {
            self.init(stringRepresentation: stringRepresentation, color: try Self.parseColor(stringRepresentation))
        } else {
            // In older devices, `_underlyingColor` will be `nil`, but it also won't be
            // accessible through `underlyingColor`.
            self.init(stringRepresentation: stringRepresentation, underlyingColor: nil)
        }
    }

        #if canImport(UIKit) && !os(watchOS)

        /// Creates a dynamic color for 2 ``ColorScheme``s.
        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        public init(light: PaywallColor, dark: PaywallColor) {
            self.init(stringRepresentation: light.stringRepresentation,
                      color: .init(light: light.underlyingColor, dark: dark.underlyingColor))
        }

        #endif

    #else

    /// Creates a color from a Hex string: `#RRGGBB` or `#RRGGBBAA`.
    public init(stringRepresentation: String) throws {
        self.init(stringRepresentation: stringRepresentation, underlyingColor: nil)
    }

    #endif

}

// MARK: - Private constructors

private extension PaywallColor {

    #if canImport(SwiftUI)

        #if swift(>=5.7)
        @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
        init(stringRepresentation: String, color: Color) {
            self.init(stringRepresentation: stringRepresentation, underlyingColor: color)
        }
        #endif

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
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
            if hexNumber <= 0xffffff {
                hexNumber <<= 8
                hexNumber |= 0xff
            }

            red = CGFloat((hexNumber & 0xff000000) >> 24) / 256
            green = CGFloat((hexNumber & 0x00ff0000) >> 16) / 256
            blue = CGFloat((hexNumber & 0x0000ff00) >> 8) / 256
            alpha = CGFloat(hexNumber & 0x000000ff) / 256

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

#if canImport(UIKit) && !os(watchOS)
private extension UIColor {

    @available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
    convenience init(light: UIColor, dark: UIColor) {
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
    }

}
#endif

#if canImport(SwiftUI) && canImport(UIKit) && !os(watchOS)
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
private extension Color {

    init(light: UIColor, dark: UIColor) {
        self.init(UIColor(light: light, dark: dark))
    }

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
public extension Color {

    /// Creates a `Color` given a light and a dark `Color`.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    init(light: Color, dark: Color) {
        self.init(light: UIColor(light), dark: UIColor(dark))
    }

    #if swift(>=5.7)

    /// Converts a `Color` into a `PaywallColor`.
    /// - Warning: This `PaywallColor` won't be able to be encoded,
    /// its ``PaywallColor/stringRepresentation`` will be undefined.
    var asPaywallColor: PaywallColor {
        return .init(stringRepresentation: "#FFFFFF", color: self)
    }

    #endif

}
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
