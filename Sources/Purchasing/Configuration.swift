//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Configuration.swift
//
//  Created by Joshua Liebowitz on 5/6/22.

import Foundation

/**
 * ``Configuration`` can be used when configuring the ``Purchases`` instance. It is not required to be used, but
 * highly recommended. This class follows a builder pattern.
 *
 * To configure your `Purchases` instance using this object, follow these steps.
 *
 * **Steps:**
 * 1. Call ``Configuration/configurationBuilder(withAPIKey:)`` To obtain a ``ConfigurationBuilder`` object.
 * 2. Set this builder's properties using the "`with(`" functions.
 * 3. Call ``ConfigurationBuilder/build()`` to obtain the `Configuration` object.
 * 4. Pass the `Configuration` object into ``Purchases/configure(withConfiguration:)``.
 *
 */
@objc(RCConfiguration) public class Configuration: NSObject {

    static let storeKitTimeoutSecondsDefault: Int = 30
    static let storeKitRequestTimeoutDefault = DispatchTimeInterval.seconds(storeKitTimeoutSecondsDefault)
    static let networkTimeoutSecondsDefault: Int = 60

    let apiKey: String
    let appUserID: String?
    let observerMode: Bool
    let userDefaults: UserDefaults?
    let storeKit2Setting: StoreKit2Setting
    let dangerousSettings: DangerousSettings?
    let networkTimeoutSeconds: Int
    let storeKit1TimeoutSeconds: Int

    override public init() {
        fatalError("Use static function configurationBuilder(withAPIKey:) to configure.")
    }

    private init(withConfigurationBuilder configurationBuilder: ConfigurationBuilder) {
        self.apiKey = configurationBuilder.apiKey
        self.appUserID = configurationBuilder.appUserID
        self.observerMode = configurationBuilder.observerMode
        self.userDefaults = configurationBuilder.userDefaults
        self.storeKit2Setting = configurationBuilder.storeKit2Setting
        self.dangerousSettings = configurationBuilder.dangerousSettings

        if configurationBuilder.storeKit1TimeoutSeconds < 5 {
            self.storeKit1TimeoutSeconds = 5
        } else {
            self.storeKit1TimeoutSeconds = configurationBuilder.storeKit1TimeoutSeconds
        }

        if configurationBuilder.networkTimeoutSeconds < 5 {
            self.networkTimeoutSeconds = 5
        } else {
            self.networkTimeoutSeconds = configurationBuilder.networkTimeoutSeconds
        }
    }

    /// Factory method for the ``ConfigurationBuilder`` object that is required to create a `Configuration`
    @objc public static func configurationBuilder(withAPIKey apiKey: String) -> ConfigurationBuilder {
        return ConfigurationBuilder(withAPIKey: apiKey)
    }

    /// The Builder for ```Configuration```.
    @objc(RCConfigurationBuilder) public class ConfigurationBuilder: NSObject {

        private(set) var apiKey: String
        private(set) var appUserID: String?
        private(set) var observerMode: Bool = false
        private(set) var userDefaults: UserDefaults?
        private(set) var storeKit2Setting: StoreKit2Setting = .init(useStoreKit2IfAvailable: false)
        private(set) var dangerousSettings: DangerousSettings?
        private(set) var networkTimeoutSeconds: Int = Configuration.networkTimeoutSecondsDefault
        private(set) var storeKit1TimeoutSeconds: Int = Configuration.storeKitTimeoutSecondsDefault

        override public init() {
            fatalError("Use init(withAPIKey:).")
        }

        /// Create a new builder with your API key.
        @objc public init(withAPIKey apiKey: String) {
            self.apiKey = apiKey
        }

        /// Update your API key.
        @objc public func with(apiKey: String) -> ConfigurationBuilder {
            self.apiKey = apiKey
            return self
        }

        /// Set or update an `appUserID`.
        @objc public func with(appUserID: String) -> ConfigurationBuilder {
            self.appUserID = appUserID
            return self
        }

        /// Set or update `observerMode`.
        @objc public func with(observerMode: Bool) -> ConfigurationBuilder {
            self.observerMode = observerMode
            return self
        }

        /// Set or update `userDefaults`.
        @objc public func with(userDefaults: UserDefaults) -> ConfigurationBuilder {
            self.userDefaults = userDefaults
            return self
        }

        /// Set or update `usesStoreKit2IfAvailable`.
        @objc public func with(usesStoreKit2IfAvailable: Bool) -> ConfigurationBuilder {
            self.storeKit2Setting = .init(useStoreKit2IfAvailable: usesStoreKit2IfAvailable)
            return self
        }

        /// Set or update `dangerousSettings`.
        @objc public func with(dangerousSettings: DangerousSettings) -> ConfigurationBuilder {
            self.dangerousSettings = dangerousSettings
            return self
        }

        /// Set or update `networkTimeoutSeconds`.
        @objc public func with(networkTimeoutSeconds: Int) -> ConfigurationBuilder {
            self.networkTimeoutSeconds = networkTimeoutSeconds
            return self
        }

        /// Set or update `storeKit1TimeoutSeconds`.
        @objc public func with(storeKit1TimeoutSeconds: Int) -> ConfigurationBuilder {
            self.storeKit1TimeoutSeconds = storeKit1TimeoutSeconds
            return self
        }

        /// Generate a ``Configuration`` object given the values configured by this builder.
        @objc public func build() -> Configuration {
            return Configuration(withConfigurationBuilder: self)
        }

    }

}
