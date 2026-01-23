//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizationProvider.swift
//
//  Created by Josh Holtz on 11/17/24.

import Foundation
import RevenueCat

#if !os(tvOS) // For Paywalls V2

struct LocalizationProvider {

    let locale: Locale
    let localizedStrings: PaywallComponent.LocalizationDictionary

}

#endif
