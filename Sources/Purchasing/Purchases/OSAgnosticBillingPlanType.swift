//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OSAgnosticBillingPlanType.swift
//
//  Created by Will Taylor on 5/12/26.

import Foundation

internal enum OSAgnosticBillingPlanType {
    case upFront
    case monthly
}

#if compiler(>=6.3.2)
internal extension OSAgnosticBillingPlanType {
    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    static func fromSKBillingPlanType(_ skBillingPlanType: SK2BillingPlanType) -> OSAgnosticBillingPlanType? {
        switch skBillingPlanType {
        case .upFront:
            return .upFront
        case .monthly:
            return .monthly
        default:
            return nil
        }
    }

    @available(iOS 26.4, macOS 26.4, tvOS 26.4, watchOS 26.4, visionOS 26.4, *)
    var skBillingPlanType: SK2BillingPlanType {
        switch self {
        case .upFront:
            return .upFront
        case .monthly:
            return .monthly
        }
    }
}
#endif
