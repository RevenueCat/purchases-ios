//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPreferredLocalesProvider.swift
//
//  Created by Antonio Pallares on 17/6/25.

@testable import RevenueCat

extension PreferredLocalesProvider {

    static func mock(preferredLocaleOverride: String? = nil,
                     locales: [String] = ["en_EN"]) -> PreferredLocalesProvider {
        return PreferredLocalesProvider(
            preferredLocaleOverride: preferredLocaleOverride,
            systemPreferredLocalesGetter: { return locales })
    }
}
