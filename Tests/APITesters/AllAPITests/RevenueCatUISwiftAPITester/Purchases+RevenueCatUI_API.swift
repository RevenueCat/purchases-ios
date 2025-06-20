//
//  Purchases+RevenueCatUI_API.swift
//  RevenueCatUISwiftAPITester
//
//  Created by Antonio Pallares on 13/6/25.
//

import RevenueCat
import RevenueCatUI

func checkPreferredUILocaleAPIs() {
    Purchases.overridePreferredUILocale("de_DE")
    Purchases.overridePreferredUILocale(nil)
    let _: RevenueCat.Configuration.Builder = Configuration
        .builder(withAPIKey: "")
        .with(preferredUILocaleOverride: "de_DE")
        .with(preferredUILocaleOverride: nil)
}
