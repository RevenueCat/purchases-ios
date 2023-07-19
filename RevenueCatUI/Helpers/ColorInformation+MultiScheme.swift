//
//  ColorInformation+MultiScheme.swift
//  
//
//  Created by Nacho Soto on 7/14/23.
//

import Foundation
import RevenueCat

#if canImport(SwiftUI) && canImport(UIKit)

extension PaywallData.Configuration.ColorInformation {

    /// - Returns: `PaywallData.Configuration.Colors` combining `light` and `dark` if they're available
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    var multiScheme: PaywallData.Configuration.Colors {
        let light = self.light
        guard let dark = self.dark else {
            // With no dark information, simply use `light`.
            return light
        }

        return .comine(light: light, dark: dark)
    }

}

extension PaywallData.Configuration.Colors {

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    static func comine(light: Self, dark: Self) -> Self {
        return .init(
            background: .init(light: light.background, dark: dark.background),
            foreground: .init(light: light.foreground, dark: dark.foreground),
            callToActionBackground: .init(light: light.callToActionBackground, dark: dark.callToActionBackground),
            callToActionForeground: .init(light: light.callToActionForeground, dark: dark.callToActionForeground)
        )
    }

}

#else

extension PaywallData.Configuration.ColorInformation {

    /// - Returns: `light` colors for platforms that don't support dark mode.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    var multiScheme: PaywallData.Configuration.Colors {
        return self.light
    }

}

#endif

#if canImport(SwiftUI)

import SwiftUI

// Helpful acessors
@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension PaywallData.Configuration.Colors {

    var backgroundColor: Color { self.background.underlyingColor }
    var foregroundColor: Color { self.foreground.underlyingColor }
    var callToActionBackgroundColor: Color { self.callToActionBackground.underlyingColor }
    var callToActionForegroundColor: Color { self.callToActionForeground.underlyingColor }

}

#endif
