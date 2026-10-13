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

/// The platform UI context for presenting SDK-owned UI.
@_spi(Internal) public struct PresentationContext: @unchecked Sendable {

    let scene: UIScene

    /// Creates a presentation context anchored to a UIKit scene.
    public init(scene: UIScene) {
        self.scene = scene
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
import AppKit

/// The platform UI context for presenting SDK-owned UI.
@_spi(Internal) public struct PresentationContext: @unchecked Sendable {

    let window: NSWindow

    /// Creates a presentation context anchored to an AppKit window.
    public init(window: NSWindow) {
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

/// The platform UI context for presenting SDK-owned UI.
@_spi(Internal) public struct PresentationContext: @unchecked Sendable {

}

#endif
