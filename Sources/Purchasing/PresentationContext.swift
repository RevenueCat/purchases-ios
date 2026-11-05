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

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

/// The platform UI context for presenting SDK-owned UI.
@_spi(Internal) public struct PresentationContext: Sendable {

    #if canImport(UIKit) && !os(watchOS)
    let scene: UIScene

    /// Creates a presentation context anchored to a UIKit scene.
    @_spi(Internal) public init(scene: UIScene) {
        self.scene = scene
    }
    #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
    let window: NSWindow

    /// Creates a presentation context anchored to an AppKit window.
    @_spi(Internal) public init(window: NSWindow) {
        self.window = window
    }
    #endif

    @MainActor
    static func defaultPresentationContext(systemInfo: SystemInfo) -> Self? {
        #if canImport(UIKit) && !os(watchOS)
        if #available(macCatalyst 13.1, *) {
            return systemInfo.sharedUIApplication?.currentWindowScene.map(Self.init(scene:))
        }

        return nil
        #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
        return (NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow).map(Self.init(window:))
        #else
        return nil
        #endif
    }

    var isValidForPresentation: Bool {
        #if canImport(UIKit) && !os(watchOS)
        return self.scene is UIWindowScene
        #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
        return true
        #else
        return false
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    @available(macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    @MainActor
    var presentationViewController: UIViewController? {
        return (self.scene as? UIWindowScene)?.currentPresentationViewController
    }
    #endif

}
