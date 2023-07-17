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
