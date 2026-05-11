//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SelectedPackageId.swift
//
//  Created by RevenueCat on 3/6/26.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

struct SelectedPackageIdKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {

    var selectedPackageId: String? {
        get { self[SelectedPackageIdKey.self] }
        set { self[SelectedPackageIdKey.self] = newValue }
    }

}

#endif
