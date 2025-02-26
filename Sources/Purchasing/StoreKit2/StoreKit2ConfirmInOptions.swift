//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ConfirmInOptions.swift
//
//  Created by Will Taylor on 2/10/25.

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Options for configuring the `confirmIn` parameter in StoreKit 2 purchases.
///
/// This struct provides platform-specific options for specifying where the purchase confirmation UI should appear.
///
/// - When UIKit is available, use `confirmInScene` to specify a `UIScene`.
/// - When AppKit is available, use `confirmInWindow` to specify an `NSWindow`.
internal struct StoreKit2ConfirmInOptions {
    #if canImport(UIKit) && !os(watchOS)
    /// The scene to show purchase confirmation UI in proximity to.
    let confirmInScene: UIScene?
    #endif

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// The window to show purchase confirmation UI in proximity to.
    let confirmInWindow: NSWindow?
    #endif
}
