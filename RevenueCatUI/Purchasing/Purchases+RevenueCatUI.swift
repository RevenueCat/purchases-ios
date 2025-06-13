//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+RevenueCatUI.swift
//
//  Created by Antonio Pallares on 13/6/25.

import Foundation
@_spi(Internal) import RevenueCat

extension RevenueCat.Purchases {

    /// Updates the preferred locale for RevenueCatUI components.
    /// - Parameter locale: The preferred locale string in the format "language-region" (e.g., "en-US").
    /// Use `nil` to reset to the default user locale.
    ///
    /// Setting this will affect the display of RevenueCat UI components, such as the Paywalls.
    public static func updatePreferredUILocale(_ locale: String?) {
        guard self.isConfigured else {
            Logger.error(Strings.failed_to_set_preferred_locale_purchases_not_configured)
            return
        }

        self.shared.preferredLocale = locale
    }
}

extension RevenueCat.Configuration.Builder {

    /// Sets the preferred locale for RevenueCatUI components.
    ///
    /// Defaults to `nil`, which means using the default user locale for RevenueCatUI components.
    public func with(preferredUILocale: String?) -> Builder {
        self.with(preferredLocale: preferredUILocale)
    }
}
