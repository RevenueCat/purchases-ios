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
//  Created by Antonio Pallares on 13/6/25.

@testable import RevenueCat

final class MockPreferredLocalesProvider: PreferredLocalesProviderType {

    var preferredLocaleOverride: String?

    var preferredLocales: [String] {
        stubbedLocales
    }

    private let stubbedLocales: [String]

    init(stubbedPreferredLocaleOverride: String? = nil,
         stubbedLocales: [String] = ["en_US"]) {
        self.preferredLocaleOverride = stubbedPreferredLocaleOverride
        self.stubbedLocales = stubbedLocales
    }

}
