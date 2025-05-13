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
        case .appStore: return .screenNoActiveTitle
        case .macAppStore: return .screenNoActiveTitle
        case .playStore: return .screenNoActiveTitle
        case .stripe: return .screenNoActiveTitle
        case .promotional: return .screenNoActiveTitle
        case .amazon: return .screenNoActiveTitle
        case .rcBilling: return .screenNoActiveTitle
        case .external: return .screenNoActiveTitle
        case .unknownStore: return .screenNoActiveTitle
        }
    }
}
