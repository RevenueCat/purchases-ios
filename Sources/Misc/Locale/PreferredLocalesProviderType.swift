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

    /// Returns a list of the user's preferred languages.
    var preferredLanguages: [String] { get }

}

/// Main ``PreferredLocalesProviderType`` implementation
final class PreferredLocalesProvider: PreferredLocalesProviderType {

    var preferredLanguages: [String] { Locale.preferredLanguages }

    /// Returns the default ``PreferredLocalesProviderType``
    static let `default`: PreferredLocalesProvider = .init()

}
