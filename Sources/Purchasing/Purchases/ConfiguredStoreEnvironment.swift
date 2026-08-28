//
//  ConfiguredStoreEnvironment.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 8/28/26.
// swiftlint:disable missing_docs

import Foundation

@objc(RCConfiguredStoreEnvironment)
@_spi(Internal) public final class ConfiguredStoreEnvironment: NSObject, @unchecked Sendable {
    private let apiKey: String
    private let fixedStoreFrontCountryCode: () -> String?

    convenience init(systemInfo: SystemInfo) {
        self.init(apiKey: systemInfo.apiKey, storeFrontCountryCode: systemInfo.storefront?.countryCode)
    }

    @_spi(Internal) public init(apiKey: String, storeFrontCountryCode: @autoclosure @escaping () -> String?) {
        self.apiKey = apiKey
        self.fixedStoreFrontCountryCode = storeFrontCountryCode
    }

    @_spi(Internal) public var storeFrontCountryCode: String? {
        return self.fixedStoreFrontCountryCode()
    }

    @_spi(Internal) public func entitlementProviderName() -> String {
        if self.apiKey.starts(with: "mac_") {
            return "mac_app_store"
        } else if self.apiKey.starts(with: "appl_") {
            return "app_store"
        } else if self.apiKey.starts(with: "test_") {
            return "test_store"
        }
        return "unknown"
    }
}

// swiftlint:enable missing_docs
