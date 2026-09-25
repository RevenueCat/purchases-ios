//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformColor.swift
//
//  Created by Chris Vasselli on 2025/07/31.

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

#if canImport(AppKit) && !canImport(UIKit)

/// AppKit stand-ins for the UIKit semantic backgrounds the Customer Center is designed around,
/// so call sites can write `PlatformColor.systemBackground` on either platform.
///
/// The iOS design pairs them for contrast: `systemBackground` is the surface a card sits on in
/// light mode and the page in dark mode, `secondarySystemBackground` the other way round.
/// `controlBackgroundColor` would not do for either: on current macOS it resolves to exactly
/// `windowBackgroundColor`, and a card drawn in one on a page of the other disappears, while
/// `underPageBackgroundColor` stays a step apart. How far, and which is lighter, depends on the
/// macOS version (before macOS 26 it is a mid gray in light mode), so a full page is better
/// drawn with the Mac's own surfaces; the Customer Center's screens are grouped forms there.
extension NSColor {

    static var systemBackground: NSColor { .windowBackgroundColor }
    static var secondarySystemBackground: NSColor { .underPageBackgroundColor }

    /// AppKit has its own `secondarySystemFill` from macOS 14, which this name shadows inside the
    /// module. Resolving the system colour by its catalog name (the plain name would refer back
    /// to this property) keeps that colour where it exists; older macOS gets the closest
    /// translucent fill it has.
    static var secondarySystemFill: NSColor {
        NSColor(catalogName: "System", colorName: "secondarySystemFillColor") ?? .quaternaryLabelColor
    }

}

#endif
