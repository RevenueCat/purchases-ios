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

    /// Default ``CustomerCenterConfigData.Localization`` value for Environment usage
    public static let `default` = CustomerCenterConfigData.Localization(locale: "en_US", localizedStrings: [:])

}

struct AppearanceKey: EnvironmentKey {

    static let defaultValue: CustomerCenterConfigData.Appearance = .default

}

extension CustomerCenterConfigData.Appearance {

    /// Default ``CustomerCenterConfigData.Appearance`` value for Environment usage
    public static let `default` = CustomerCenterConfigData.Appearance(mode: .system)

}

extension EnvironmentValues {

    var localization: CustomerCenterConfigData.Localization {
        get { self[LocalizationKey.self] }
        set { self[LocalizationKey.self] = newValue }
    }

    var appearance: CustomerCenterConfigData.Appearance {
        get { self[AppearanceKey.self] }
        set { self[AppearanceKey.self] = newValue }
    }

}
