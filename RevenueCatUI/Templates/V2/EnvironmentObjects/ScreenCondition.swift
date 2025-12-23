//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ScreenCondition.swift
//
//  Created by Josh Holtz on 11/14/24.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

enum ScreenCondition {

    case compact, medium, expanded

    static func from(_ sizeClass: UserInterfaceSizeClass?) -> Self {
        guard let sizeClass else {
            return .compact
        }

        switch sizeClass {
        case .compact:
            return .compact
        case .regular:
            return .medium
        @unknown default:
            return .compact
        }
    }

}

struct ScreenConditionKey: EnvironmentKey {
    static let defaultValue = ScreenCondition.compact
}

extension EnvironmentValues {

    var screenCondition: ScreenCondition {
        get { self[ScreenConditionKey.self] }
        set { self[ScreenConditionKey.self] = newValue }
    }

}

#endif
