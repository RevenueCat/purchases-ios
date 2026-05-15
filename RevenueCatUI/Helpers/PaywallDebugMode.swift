//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallDebugMode.swift
//
//  Centralized environment-variable flags consumed by V2 paywall views to
//  opt-in to test-only behaviors (screenshot mode, cross-platform layout
//  extraction, …). These are NOT part of the public SDK contract — they
//  exist so internal tooling (and snapshot / UITest harnesses) can request
//  richer instrumentation without changing production VoiceOver behavior.

import Foundation

/// Process-level debug switches for V2 paywall rendering.
///
/// All flags default to `false` (the production behavior). They flip to `true`
/// only when the corresponding environment variable is set on the process
/// hosting the paywall view — typically by an XCUITest launch environment or
/// a snapshot-test harness.
enum PaywallDebugMode {

    /// When `true`, V2 paywall component views expose richer accessibility
    /// information so the cross-platform layout extractor
    /// (`PaywallAccessibilityTreeTests`) can locate every dashboard
    /// component in the XCUITest tree by its `componentId`. Specifically:
    ///
    /// - Image components are NOT `.accessibilityHidden` — they surface as
    ///   queryable elements.
    /// - Every V2 component view that carries a dashboard `id` becomes its
    ///   own `.accessibilityElement(children: .contain)` so SwiftUI doesn't
    ///   merge it into the parent stack's identity.
    ///
    /// Off by default — production paywalls keep their curated VoiceOver
    /// behavior (decorative images stay hidden, container nodes can merge).
    /// Set `RC_LAYOUT_EXTRACTOR_MODE=1` in the host process to opt in.
    static var isLayoutExtractorActive: Bool {
        ProcessInfo.processInfo.environment["RC_LAYOUT_EXTRACTOR_MODE"] == "1"
    }
}
