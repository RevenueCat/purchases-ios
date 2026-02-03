//
//  VersionedViewModifiers.swift
//  RCTTester
//

import SwiftUI

extension View {

    /// Applies a glass effect with regular interactive style in a circle shape.
    /// Only available on iOS 26+, visionOS 26+, macOS 26+, tvOS 26+, watchOS 26+.
    /// On earlier OS versions, applies the `fallback` modifier if provided, otherwise does nothing.
    /// - Parameter fallback: A closure that receives the view and returns a modified view for older OS versions.
    @ViewBuilder
    func glassEffectRegularInteractiveInCircle<Fallback: View>(
        fallback: ((Self) -> Fallback)? = nil
    ) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .circle)
        } else if let fallback {
            fallback(self)
        } else {
            self
        }
    }
}
