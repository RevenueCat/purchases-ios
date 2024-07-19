//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterEnvironment.swift
//
//  Created by Cesar de la Vega on 19/7/24.

import Foundation
import RevenueCat
import SwiftUI

struct LocalizationKey: EnvironmentKey {

    static let defaultValue: CustomerCenterConfigData.Localization = .default

}

extension CustomerCenterConfigData.Localization {

    public static let `default` = CustomerCenterConfigData.Localization(locale: "en_US", localizedStrings: [:])

}

extension EnvironmentValues {

    var localization: CustomerCenterConfigData.Localization {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }

}
