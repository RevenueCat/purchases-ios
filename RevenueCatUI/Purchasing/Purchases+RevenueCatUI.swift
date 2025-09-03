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

    /// Overrides the preferred locale for RevenueCatUI components.
    /// - Parameter locale: A locale string in the format "language_region" (e.g., "en_US").
    /// Use `nil` to remove the override and use the default user locale determined by the system.
    ///
    /// Setting this will affect the display of RevenueCat UI components, such as the Paywalls.
    /// - Important: This method only takes effect after `Purchases` has been configured.
    public func overridePreferredUILocale(_ locale: String?) {
        self.overridePreferredLocale(locale)
    }
}

extension RevenueCat.Configuration.Builder {

    /// Overrides the preferred locale for RevenueCatUI components.
    ///
    /// - Parameter preferredUILocaleOverride: A locale string in the format "language_region" (e.g., "en_US").
    ///
    /// Defaults to `nil`, which means using the default user locale for RevenueCatUI components.
    public func with(preferredUILocaleOverride: String?) -> RevenueCat.Configuration.Builder {
        return self.with(preferredLocale: preferredUILocaleOverride)
    }
}
