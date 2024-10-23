//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ContactSupportUtilities.swift
//
//  Created by Antonio Rico Diez on 2024-10-23.

import Foundation
import RevenueCat
#if canImport(UIKit)
import UIKit
#endif

extension CustomerCenterConfigData.Support {

    func calculateBody(_ localization: CustomerCenterConfigData.Localization,
                       dataToInclude: [(String, String)]? = nil) -> String {
        let infoToInclude: [(String, String)]
        if let dataToInclude {
            infoToInclude = dataToInclude
        } else {
            infoToInclude = Self.defaultData(localization)
        }
        let defaultBody =
            """
            \(localization.commonLocalizedString(for: .defaultBody))

            ---------------------------
            \(localization.commonLocalizedString(for: .defaultExtraInformation))
            \(infoToInclude.map { (key, value) in
                "- \(key): \(value)"
            }.joined(separator: "\n"))
            """
        return defaultBody
    }

    private static func defaultData(_ localization: CustomerCenterConfigData.Localization) -> [(String, String)] {
        let unknown = localization.commonLocalizedString(for: .unknown)
        var iOSVersion = unknown
        #if canImport(UIKit)
        iOSVersion = UIDevice.current.systemVersion
        #endif
        let userID = Purchases.isConfigured ? Purchases.shared.appUserID : unknown
        let storeFrontCountryCode = Purchases.isConfigured ? Purchases.shared.storeFrontCountryCode ?? unknown : unknown

        return [
            ("RCUserID", userID),
            ("StoreFront Country Code", storeFrontCountryCode),
            ("App Version", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? unknown),
            ("iOS Version", iOSVersion)
        ]
    }
}
