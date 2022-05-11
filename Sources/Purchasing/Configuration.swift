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
 * 1. Call ``Configuration/builder(withAPIKey:)`` To obtain a ``Builder`` object.
 * 2. Set this builder's properties using the "`with(`" functions.
 * 3. Call ``Builder/build()`` to obtain the `Configuration` object.
 * 4. Pass the `Configuration` object into ``Purchases/configure(with:)``.
 *
 * ```swift
 * let configuration = Configuration.Builder(withAPIKey: "MyKey")
 *                                  .with(appUserID: "SomeAppUserID")
 *                                  .with(userDefaults: myUserDefaults)
 *                                  .with(networkTimeoutSeconds: 15)
 *                                  .with(storeKit1TimeoutSeconds: 15)
 *                                  .with(usesStoreKit2IfAvailable: true)
 *                                  .build()
 *  Purchases.configure(with: configuration)
 * ```
 */
@objc(RCConfiguration) public class Configuration: NSObject {

    static let storeKitRequestTimeoutDefault = TimeInterval(30)
    static let networkTimeoutDefault = TimeInterval(60)

    let apiKey: String
    let appUserID: String?
    let observerMode: Bool
    let userDefaults: UserDefaults?
    let storeKit2Setting: StoreKit2Setting
    let dangerousSettings: DangerousSettings?
    let networkTimeoutSeconds: TimeInterval
    let storeKit1TimeoutSeconds: TimeInterval

    private init(with configurationBuilder: Builder) {
        self.apiKey = configurationBuilder.apiKey
        self.appUserID = configurationBuilder.appUserID
        self.observerMode = configurationBuilder.observerMode
        self.userDefaults = configurationBuilder.userDefaults
        self.storeKit2Setting = configurationBuilder.storeKit2Setting
        self.dangerousSettings = configurationBuilder.dangerousSettings
        self.storeKit1TimeoutSeconds = configurationBuilder.storeKit1Timeout
        self.networkTimeoutSeconds = configurationBuilder.networkTimeoutSeconds
    }

    /// Factory method for the ``Configuration/Builder`` object that is required to create a `Configuration`
    @objc public static func builder(withAPIKey apiKey: String) -> Builder {
        return Builder(withAPIKey: apiKey)
    }

    /// The Builder for ```Configuration```.
    @objc(RCConfigurationBuilder) public class Builder: NSObject {

        static let minimumTimeout = TimeInterval(5)

        private(set) var apiKey: String
        private(set) var appUserID: String?
        private(set) var observerMode: Bool = false
        private(set) var userDefaults: UserDefaults?
        private(set) var storeKit2Setting: StoreKit2Setting = .init(useStoreKit2IfAvailable: false)
        private(set) var dangerousSettings: DangerousSettings?
        private(set) var networkTimeoutSeconds = Configuration.networkTimeoutDefault
        private(set) var storeKit1Timeout = Configuration.storeKitRequestTimeoutDefault

        /// Create a new builder with your API key.
        @objc public init(withAPIKey apiKey: String) {
            self.apiKey = apiKey
        }

        /// Update your API key.
        @objc public func with(apiKey: String) -> Builder {
            self.apiKey = apiKey
            return self
        }

        /// Set an `appUserID`.
        @objc public func with(appUserID: String) -> Builder {
            self.appUserID = appUserID
            return self
        }

        /// Set `observerMode`.,
        @objc public func with(observerMode: Bool) -> Builder {
            self.observerMode = observerMode
            return self
        }

        /// Set `userDefaults`.
        @objc public func with(userDefaults: UserDefaults) -> Builder {
            self.userDefaults = userDefaults
            return self
        }

        /// Set `usesStoreKit2IfAvailable`.
        @objc public func with(usesStoreKit2IfAvailable: Bool) -> Builder {
            self.storeKit2Setting = .init(useStoreKit2IfAvailable: usesStoreKit2IfAvailable)
            return self
        }

        /// Set `dangerousSettings`.
        @objc public func with(dangerousSettings: DangerousSettings) -> Builder {
            self.dangerousSettings = dangerousSettings
            return self
        }

        /// Set `networkTimeoutSeconds`.
        @objc public func with(networkTimeoutSeconds: TimeInterval) -> Builder {
            self.networkTimeoutSeconds = valueOrMinimum(timeout: networkTimeoutSeconds)
            return self
        }

        /// Set `storeKit1Timeout`.
        @objc public func with(storeKit1TimeoutSeconds: TimeInterval) -> Builder {
            self.storeKit1Timeout = valueOrMinimum(timeout: storeKit1TimeoutSeconds)
            return self
        }

        /// Generate a ``Configuration`` object given the values configured by this builder.
        @objc public func build() -> Configuration {
            return Configuration(with: self)
        }

        private func valueOrMinimum(timeout: TimeInterval) -> TimeInterval {
            guard timeout >= Self.minimumTimeout else {
                Logger.warn(
                    """
                    Timeout value: \(timeout) is lower than the minimum, setting it
                    to the mimimum: (\(Self.minimumTimeout))
                    """
                )
                return Self.minimumTimeout
            }

            return timeout
        }

    }

}
