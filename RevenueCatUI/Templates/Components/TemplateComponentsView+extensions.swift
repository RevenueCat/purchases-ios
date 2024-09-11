//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateComponentsView+extensions.swift
//
//  Created by James Borthwick on 2024-09-03.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateComponentsView {

    static func fallbackPaywallViewModels(error: Error? = nil) -> PaywallComponentViewModel {

        let errorDict: PaywallComponent.LocalizationDictionary = ["errorID": .string("Error creating paywall")]

        let localizationInfo = LocalizationProvider.LocalizationInfo(
            locale: Locale.current,
            localizedStrings: errorDict
        )
        let localizationProvider = LocalizationProvider(
            preferred: localizationInfo,
            default: localizationInfo
        )

        let textComponent = PaywallComponent.TextComponent(
            textLid: "errorID",
            color: PaywallComponent.ColorInfo(light: "#000000")
        )

        // swiftlint:disable:next force_try
        return try! PaywallComponentViewModel.text(
            TextComponentViewModel(
                localizationProvider: localizationProvider,
                component: textComponent
            )
        )

    }

}

extension Locale {

    internal static var preferredLocales: [Self] {
        return Self.preferredLanguages.map(Locale.init(identifier:))
    }

    internal func matchesLanguage(_ rhs: Locale) -> Bool {
        self.removingRegion == rhs.removingRegion
    }

    // swiftlint:disable:next identifier_name
    private var rc_languageCode: String? {
        #if swift(>=5.9)
        // `Locale.languageCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.languageCode?.identifier
        } else {
            return self.languageCode
        }
        #else
        return self.languageCode
        #endif
    }

    /// - Returns: the same locale as `self` but removing its region.
    private var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

}
#endif
