//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFontProvider.swift
//
//  Created by Nacho Soto on 8/8/23.

import SwiftUI

/// A type that returns a font for a given `Font.TextStyle`.
///
/// You can use one of the provided implementations, or make your own:
/// - ``DefaultPaywallFontProvider``
/// - ``CustomPaywallFontProvider``
public protocol PaywallFontProvider {

    /// - Returns: Desired `Font` for the given `Font.TextStyle`.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func font(for textStyle: Font.TextStyle) -> Font

}

/// Default ``PaywallFontProvider`` which uses the system default font
/// supporting dynamic type.
open class DefaultPaywallFontProvider: PaywallFontProvider {

    // swiftlint:disable:next missing_docs
    public init() {}

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    // swiftlint:disable:next cyclomatic_complexity missing_docs
    open func font(for textStyle: Font.TextStyle) -> Font {
        switch textStyle {
        case .largeTitle: return .largeTitle
        case .title: return .title
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption
        case .caption2: return .caption2

        // Font.TextStyle.caption3 was introduced with tvOS 18.0/Xcode 16.0, but
        // was removed without warning in Xcode 16.1/tvOS 18.1 and hasn't been reintroduced
        // since.
        // Xcode 16.0 shipped with Swift compiler 6.0, and Xcode 16.1 shipped with Swift compiler 6.0.2,
        // this allows us to target builds built only with Xcode 16.0.
        //
        // We will need to reevaluate this if and when Font.TextStyle.caption3 is reintroduced.
        #if compiler(>=6.0) && compiler(<6.0.2) && os(tvOS)
        case .caption3: if #available(tvOS 18.0, *) {
            return .system(.caption3)
        } else {
            return .caption2
        }
        #endif

        #if swift(>=5.9) && os(visionOS)
        case .extraLargeTitle: return .extraLargeTitle
        case .extraLargeTitle2: return .extraLargeTitle2
        #endif
        @unknown default: return .body
        }
    }

}

/// A ``PaywallFontProvider`` implementation that allows you to provide a custom
/// font name, and it will automatically scale up based on the size category.
open class CustomPaywallFontProvider: PaywallFontProvider {

    private let fontName: String

    /// Creates a ``CustomPaywallFontProvider`` with a name.
    public init(fontName: String) {
        self.fontName = fontName
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    // swiftlint:disable:next missing_docs
    open func font(for textStyle: Font.TextStyle) -> Font {
        return Font.custom(self.fontName,
                           size: PlatformFont.preferredFont(forTextStyle: textStyle.style).pointSize,
                           relativeTo: textStyle)
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension Font.TextStyle {

    var style: PlatformFont.TextStyle {
        switch self {
        #if os(tvOS)
        case .largeTitle: return .title1
        #else
        case .largeTitle: return .largeTitle
        #endif
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2

        // Font.TextStyle.caption3 was introduced with tvOS 18.0/Xcode 16.0, but
        // was removed without warning in Xcode 16.1/tvOS 18.1 and hasn't been reintroduced
        // since.
        // Xcode 16.0 shipped with Swift compiler 6.0, and Xcode 16.1 shipped with Swift compiler 6.0.2,
        // this allows us to target builds built only with Xcode 16.0.
        //
        // We will need to reevaluate this if and when Font.TextStyle.caption3 is reintroduced.
        #if compiler(>=6.0) && compiler(<6.0.2) && os(tvOS)
        case .caption3: return .caption2
        #endif

        #if swift(>=5.9) && os(visionOS)
        case .extraLargeTitle: return .extraLargeTitle
        case .extraLargeTitle2: return .extraLargeTitle2
        #endif

        @unknown default: return .body
        }
    }

}
