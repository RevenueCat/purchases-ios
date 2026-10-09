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

#if canImport(UIKit) && !os(watchOS)

extension UIApplication {

    /// The default context for presenting purchase-related UI.
    @_spi(Internal)
    @available(macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    @MainActor
    public var defaultPurchasePresentationContext: PurchasePresentationContext? {
        return self.currentWindowScene.map(PurchasePresentationContext.init(scene:))
    }

}

extension PurchasePresentationContext {

    @MainActor
    static func defaultPresentationContext(systemInfo: SystemInfo) -> Self? {
        if #available(macCatalyst 13.1, *) {
            return systemInfo.sharedUIApplication?.defaultPurchasePresentationContext
        }

        return nil
    }

    var isValidForPresentation: Bool {
        return self.scene is UIWindowScene
    }

    @available(macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    @MainActor
    var presentationViewController: UIViewController? {
        return (self.scene as? UIWindowScene)?.currentPresentationViewController
    }

}

#elseif canImport(AppKit) && !targetEnvironment(macCatalyst)

extension NSApplication {

    /// The default context for presenting purchase-related UI.
    @_spi(Internal)
    @MainActor
    public var defaultPurchasePresentationContext: PurchasePresentationContext? {
        return (self.keyWindow ?? self.mainWindow).map(PurchasePresentationContext.init(window:))
    }

}

extension PurchasePresentationContext {

    @MainActor
    static func defaultPresentationContext(systemInfo: SystemInfo) -> Self? {
        return NSApplication.shared.defaultPurchasePresentationContext
    }

    var isValidForPresentation: Bool {
        return true
    }

}

#endif
