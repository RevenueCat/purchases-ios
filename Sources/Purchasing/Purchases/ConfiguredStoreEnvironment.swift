//
//  ConfiguredStoreEnvironment.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 8/28/26.
// swiftlint:disable missing_docs

import Foundation

@objc(RCConfiguredStoreEnvironment)
@_spi(Internal) public final class ConfiguredStoreEnvironment: NSObject {
    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    @_spi(Internal) public var storeFrontCountryCode: String? {
        return systemInfo.storefront?.countryCode
    }

    @_spi(Internal) public func entitlementProviderName() -> String {
        let apiKey = systemInfo.apiKey
        if apiKey.starts(with: "mac_") {
            return "mac_app_store"
        } else if apiKey.starts(with: "appl_") {
            return "app_store"
        } else if apiKey.starts(with: "test_") {
            return "test_store"
        }
        return "unknown"
    }
}

// swiftlint:enable missing_docs
