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
@_spi(Internal) import RevenueCat
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterConfigData.Support {

    func calculateBody(_ localization: CustomerCenterConfigData.Localization,
                       dataToInclude: [(String, String)]? = nil,
                       purchasesProvider: CustomerCenterPurchasesType) -> String {
        let infoToInclude: [(String, String)]
        if let dataToInclude {
            infoToInclude = dataToInclude
        } else {
            infoToInclude = Self.defaultData(localization, purchasesProvider: purchasesProvider)
        }
        let defaultBody =
            """
            \(localization[.defaultBody])

            ---------------------------
            \(infoToInclude.map { (key, value) in
                "- \(key): \(value)"
            }.joined(separator: "\n"))
            """
        return defaultBody
    }

    private static func defaultData(_ localization: CustomerCenterConfigData.Localization,
                                    purchasesProvider: CustomerCenterPurchasesType) -> [(String, String)] {
        let unknown = localization[.unknown]
        var osVersion = unknown
        var deviceModel = unknown
        #if canImport(UIKit) && !os(watchOS)
        osVersion = UIDevice.current.systemVersion
        deviceModel = UIDevice.current.model
        #endif
        let userID = Purchases.isConfigured ? purchasesProvider.appUserID : unknown
        let storeFrontCountryCode = purchasesProvider.isConfigured ?
        purchasesProvider.storeFrontCountryCode ?? unknown : unknown

        return [
            ("RC User ID", userID),
            ("App Version", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? unknown),
            ("Device", deviceModel),
            ("OS Version", osVersion),
            ("StoreFront Country Code", storeFrontCountryCode)
        ]
    }
}
