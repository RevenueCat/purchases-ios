//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PreferredLocalesProvider.swift
//
//  Created by Cesar de la Vega on 1/7/24.

import Foundation

/// A type that can determine the current list of preferred locales.
protocol PreferredLocalesProviderType {

    /// Developer-set preferred locale that takes precedence over the system preferred locales.
    var preferredLocaleOverride: String? { get set }

    /// Returns a list of the user's preferred languages.
    var preferredLocales: [String] { get }

}

/// Main ``PreferredLocalesProviderType`` implementation
final class PreferredLocalesProvider: PreferredLocalesProviderType {

    var preferredLocaleOverride: String?

    var preferredLocales: [String] { Locale.preferredLanguages }

    init(preferredLocaleOverride: String?) {
        self.preferredLocaleOverride = preferredLocaleOverride
    }
}
