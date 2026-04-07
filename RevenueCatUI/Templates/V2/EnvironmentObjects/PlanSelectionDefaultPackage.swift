//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlanSelectionDefaultPackage.swift
//
//  Created by RevenueCat on 7/4/26.

import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

/// Configured default `Package` for the current scope (root offering or active tab), used for plan-selection analytics.
private struct PlanSelectionDefaultPackageKey: EnvironmentKey {
    static let defaultValue: Package? = nil
}

extension EnvironmentValues {

    var planSelectionDefaultPackage: Package? {
        get { self[PlanSelectionDefaultPackageKey.self] }
        set { self[PlanSelectionDefaultPackageKey.self] = newValue }
    }

}

#endif
