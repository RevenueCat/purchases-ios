//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  VoiceOverEnabledOverrideKey.swift

import SwiftUI

#if !os(tvOS) // For Paywalls V2

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct VoiceOverEnabledOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    /// Overrides `accessibilityVoiceOverEnabled`, which is read-only, for preview and test
    /// contexts. XCUITest cannot turn VoiceOver on, so nothing else can reach the spoken path.
    @_spi(Internal) public var voiceOverEnabledOverride: Bool? {
        get { self[VoiceOverEnabledOverrideKey.self] }
        set { self[VoiceOverEnabledOverrideKey.self] = newValue }
    }

}

#endif

#endif
