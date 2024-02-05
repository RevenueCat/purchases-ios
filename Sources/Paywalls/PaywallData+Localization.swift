//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallData+Localization.swift
//
//  Created by Nacho Soto on 8/10/23.

import Foundation

public extension PaywallData {

    /// - Returns: the ``PaywallData/LocalizedConfiguration-swift.struct``  to be used
    /// based on `Locale.current` or `Locale.preferredLocales`.
    var localizedConfiguration: LocalizedConfiguration {
        return self.localizedConfiguration(for: Self.localesOrderedByPriority)
    }

    // Visible for testing
    internal func localizedConfiguration(for locales: [Locale]) -> LocalizedConfiguration {
        return locales
            .lazy
            .compactMap(self.config(for:))
            .first { _ in true } // See https://github.com/apple/swift/issues/55374
            ?? self.fallbackLocalizedConfiguration
    }

    // Visible for testing
    /// - Returns: The list of locales that paywalls should try to search for.
    /// Includes `Locale.current` and `Locale.preferredLanguages`.
    internal static var localesOrderedByPriority: [Locale] {
        var result = [.current] + Locale.preferredLocales

        if let withoutRegion = Locale.current.removingRegion {
            result.append(withoutRegion)
        }

        return result
    }

    private var fallbackLocalizedConfiguration: LocalizedConfiguration {
        // This can't happen because `localization` has `@EnsureNonEmptyCollectionDecodable`.
        guard let result = self.localization.first?.value else {
            fatalError("Corrupted data: localization is empty.")
        }

        return result
    }

}

// MARK: -

extension Locale {

    fileprivate static var preferredLocales: [Self] {
        return Self.preferredLanguages.map(Locale.init(identifier:))
    }

}
