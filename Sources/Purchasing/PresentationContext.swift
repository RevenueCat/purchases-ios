//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PresentationContext.swift
//
//  Created by Rick van der Linden on 7/10/26.

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// The platform UI context for presenting SDK-owned UI.
@_spi(Internal) public struct PresentationContext: @unchecked Sendable {

    #if canImport(UIKit) && !os(watchOS)

    let scene: UIScene

    /// Creates a presentation context anchored to a UIKit scene.
    public init(scene: UIScene) {
        self.scene = scene
    }

    #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)

    let window: NSWindow

    /// Creates a presentation context anchored to an AppKit window.
    public init(window: NSWindow) {
        self.window = window
    }

    #endif

}
