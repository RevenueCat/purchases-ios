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
        case .appStore: return .appStore
        case .macAppStore: return .macAppStore
        case .playStore: return .googlePlayStore
        case .stripe: return .stripe
        case .promotional: return .promotional
        case .amazon: return .amazonStore
        case .rcBilling: return .rcBilling
        case .external: return .externalStore
        case .unknownStore: return .unknownStore
        }
    }
}
