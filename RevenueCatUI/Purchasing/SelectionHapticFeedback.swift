//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SelectionHapticFeedback.swift
//

import Foundation
import SwiftUI

#if canImport(UIKit) && os(iOS)
import UIKit
#endif

/// Fires a native selection-changed haptic when the user changes the selected package or tab
/// on a Paywalls V2 screen. Wraps a closure (like `ComponentInteractionLogger`) so tests can
/// inject a spy without touching real UIKit APIs.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SelectionHapticFeedback {

    private let action: () -> Void
    private let prepareAction: () -> Void

    init(
        action: @escaping () -> Void = Self.defaultAction,
        prepare: @escaping () -> Void = Self.defaultPrepare
    ) {
        self.action = action
        self.prepareAction = prepare
    }

    func callAsFunction() {
        self.action()
    }

    /// Warms up the haptics engine ahead of the first selection. The first haptic in a process
    /// loads the underlying engine on the main thread, a one-time cost that does not decay.
    /// Calling this on paywall appear pays it off the selection's critical path, so the first
    /// tap's highlight render isn't stalled behind the engine load. Call sites invoke this on
    /// appear of the selectable package/tab.
    func prepare() {
        self.prepareAction()
    }

    #if canImport(UIKit) && os(iOS)
    // One shared generator kept warm across selections, instead of allocating and re-warming
    // a fresh one on every tap.
    private static let generator = UISelectionFeedbackGenerator()
    #endif

    private static func defaultAction() {
        #if canImport(UIKit) && os(iOS)
        Self.generator.selectionChanged()
        // Keep the engine warm for the next selection.
        Self.generator.prepare()
        #endif
    }

    private static func defaultPrepare() {
        #if canImport(UIKit) && os(iOS)
        Self.generator.prepare()
        #endif
    }

    // Once the deployment target reaches iOS 17, this can be replaced by the SwiftUI-native
    // `.sensoryFeedback(.selection, trigger:)` modifier attached directly at each call site,
    // dropping this imperative UIKit path.
}

/// `EnvironmentKey` for storing the paywall package/tab selection haptic feedback.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SelectionHapticFeedbackKey: EnvironmentKey {
    static let defaultValue: SelectionHapticFeedback = .init()
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var selectionHapticFeedback: SelectionHapticFeedback {
        get { self[SelectionHapticFeedbackKey.self] }
        set { self[SelectionHapticFeedbackKey.self] = newValue }
    }
}
