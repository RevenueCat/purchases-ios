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

/// A platform UI context where the SDK can present UI.
@_spi(Internal) public struct PresentationContext: @unchecked Sendable {

    let scene: UIScene
    let window: UIWindow?

    /// Creates a presentation context anchored to a UIKit scene.
    @_spi(Internal) public init(scene: UIScene) {
        self.scene = scene
        self.window = nil
    }

    /// Creates a presentation context anchored to a UIKit window.
    @_spi(Internal) public init?(window: UIWindow) {
        guard let scene = window.windowScene else { return nil }

        self.scene = scene
        self.window = window
    }

    @MainActor
    static func defaultPresentationContext(systemInfo: SystemInfo) -> Self? {
        if #available(macCatalyst 13.1, *) {
            return systemInfo.sharedUIApplication?.currentWindowScene.map(Self.init(scene:))
        }

        return nil
    }

    var isValidForPresentation: Bool {
        return self.scene is UIWindowScene
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

        return (self.scene as? UIWindowScene)?.currentPresentationViewController
    }

}

#elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

/// A platform UI context where the SDK can present UI.
@_spi(Internal) public struct PresentationContext: @unchecked Sendable {

    let window: NSWindow

    /// Creates a presentation context anchored to an AppKit window.
    @_spi(Internal) public init(window: NSWindow) {
        self.window = window
    }

    @MainActor
    static func defaultPresentationContext(systemInfo: SystemInfo) -> Self? {
        return (NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow).map(Self.init(window:))
    }

    var isValidForPresentation: Bool {
        return true
    }

}

#else

/// A platform UI context where the SDK can present UI.
@_spi(Internal) public struct PresentationContext: @unchecked Sendable {

}

#endif
