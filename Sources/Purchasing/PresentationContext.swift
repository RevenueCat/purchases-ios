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

/// A platform UI context where the SDK can present UI.
@_spi(Internal) public struct PresentationContext: Sendable {

    let allowsDefaultPresentationFallback: Bool

    #if canImport(UIKit) && !os(watchOS)
    let scene: UIScene
    let window: UIWindow?

    /// Creates a presentation context anchored to a UIKit scene.
    @_spi(Internal) public init(scene: UIScene) {
        self.init(scene: scene, allowsDefaultPresentationFallback: false)
    }

    /// Creates a presentation context anchored to a UIKit scene with configurable fallback behavior.
    @_spi(Internal) public init(scene: UIScene, allowsDefaultPresentationFallback: Bool) {
        self.allowsDefaultPresentationFallback = allowsDefaultPresentationFallback
        self.scene = scene
        self.window = nil
    }

    /// Creates a presentation context anchored to a UIKit window.
    @_spi(Internal) public init?(window: UIWindow) {
        self.init(window: window, allowsDefaultPresentationFallback: false)
    }

    /// Creates a presentation context anchored to a UIKit window with configurable fallback behavior.
    @_spi(Internal) public init?(window: UIWindow, allowsDefaultPresentationFallback: Bool) {
        guard let scene = window.windowScene else { return nil }

        self.allowsDefaultPresentationFallback = allowsDefaultPresentationFallback
        self.scene = scene
        self.window = window
    }
    #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
    let window: NSWindow

    /// Creates a presentation context anchored to an AppKit window.
    @_spi(Internal) public init(window: NSWindow) {
        self.init(window: window, allowsDefaultPresentationFallback: false)
    }

    /// Creates a presentation context anchored to an AppKit window with configurable fallback behavior.
    @_spi(Internal) public init(window: NSWindow, allowsDefaultPresentationFallback: Bool) {
        self.allowsDefaultPresentationFallback = allowsDefaultPresentationFallback
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

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    var sheetPresentationWindow: NSWindow? {
        var window = self.window
        while let attachedSheet = window.attachedSheet {
            window = attachedSheet
        }

        return window.isVisible ? window : nil
    }
    #endif

    #if canImport(UIKit) && !os(watchOS)
    /// The window scene represented by this context, if any.
    @_spi(Internal) public var windowScene: UIWindowScene? {
        return self.scene as? UIWindowScene
    }

    /// The view controller suitable for presenting UI from this context.
    @available(macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    @MainActor
    @_spi(Internal) public var presentationViewController: UIViewController? {
        if let window = self.window {
            return window.currentPresentationViewController
        }

        return self.windowScene?.currentPresentationViewController
    }
    #endif

}
