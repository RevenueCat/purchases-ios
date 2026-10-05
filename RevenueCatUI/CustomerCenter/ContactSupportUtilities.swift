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

@available(iOS 15.0, macOS 13.0, tvOS 15.0, watchOS 8.0, *)
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
        #elseif os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        deviceModel = Self.macHardwareModel ?? unknown
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

    #if os(macOS)
    /// The Mac's hardware model identifier (for example `Mac15,6`), read once from `hw.model`:
    /// the support URL is rebuilt whenever the screen offering it redraws.
    private static let macHardwareModel: String? = {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }()
    #endif
}
