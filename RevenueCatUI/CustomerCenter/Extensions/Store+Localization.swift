//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Store+Localization.swift
//
//
//  Created by Facundo Menzella on 14/1/25.
//
import RevenueCat

extension Store {

    var localizationKey: CCLocalizedString {
        switch self {
        case .appStore: return .storeAppStore
        case .macAppStore: return .storeMacAppStore
        case .playStore: return .storePlayStore
        case .stripe: return .storeStripe
        case .promotional: return .storePromotional
        case .amazon: return .storeAmazon
        case .rcBilling: return .storeRCBilling
        case .external: return .storeExternal
        case .unknownStore: return .storeUnknownStore
        }
    }
}
