//
//  ConfiguredStoreEnvironment.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 8/28/26.
// swiftlint:disable missing_docs

import Foundation

@_spi(Internal) public class ConfiguredStoreEnvironment {
    init() { }

    func entitlementProviderName() -> String {
        if self is TestStore {
            return "test_store"
        }
        if self is AppleAppStore {
            return "app_store"
        }
        if self is AppleMacAppStore {
            return "mac_app_store"
        }
        return "unknown"
    }

    static func from(apiKey: String) -> ConfiguredStoreEnvironment {
        if apiKey.starts(with: "mac_") {
            return AppleMacAppStore()
        } else if apiKey.starts(with: "appl_") {
            return AppleAppStore()
        } else if apiKey.starts(with: "test_") {
            return TestStore()
        } else {
            return ConfiguredStoreEnvironment()
        }
    }
}

@_spi(Internal) public final class TestStore: ConfiguredStoreEnvironment {}
@_spi(Internal) public final class AppleAppStore: ConfiguredStoreEnvironment {}
@_spi(Internal) public final class AppleMacAppStore: ConfiguredStoreEnvironment {}

// swiftlint:enable missing_docs
