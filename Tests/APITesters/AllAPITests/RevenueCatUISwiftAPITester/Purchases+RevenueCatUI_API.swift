//
//  Purchases+RevenueCatUI_API.swift
//  RevenueCatUISwiftAPITester
//
//  Created by Antonio Pallares on 13/6/25.
//

import RevenueCat
import RevenueCatUI

func checkPreferredUILocaleAPIs() {
    Purchases.updatePreferredUILocale("de-DE")
    let _: RevenueCat.Configuration.Builder = Configuration
        .builder(withAPIKey: "")
        .with(preferredUILocale: "de-DE")
}
