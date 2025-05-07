//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementInfo+Extensions.swift
//
//  Created by Cesar de la Vega on 6/5/25.

import RevenueCat

internal extension PeriodType {

    var stringValue: String {
        switch self {
        case .normal: return "normal"
        case .intro: return "intro"
        case .trial: return "trial"
        case .prepaid: return "prepaid"
        }
    }

}
