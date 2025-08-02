//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  JustifyContent.swift
//
//  Created by Josh Holtz on 11/11/24.

import Foundation
import RevenueCat

#if !os(tvOS) // For Paywalls V2

enum JustifyContent {
    case start, center, end, spaceBetween, spaceAround, spaceEvenly
}

extension PaywallComponent.FlexDistribution {

    var justifyContent: JustifyContent {
        switch self {
        case .start:
            return .start
        case .center:
            return .center
        case .end:
            return .end
        case .spaceBetween:
            return .spaceBetween
        case .spaceAround:
            return .spaceAround
        case .spaceEvenly:
            return .spaceEvenly
        }
    }

}

#endif
