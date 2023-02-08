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
 * 4. Pass the `Configuration` object into ``Purchases/configure(with:)-6oipy``.
 *
 * ```swift
 * let configuration = Configuration.Builder(withAPIKey: "MyKey")
 *                                  .with(appUserID: "SomeAppUserID")
 *                                  .with(userDefaults: myUserDefaults)
 *                                  .with(networkTimeout: 15)
 *                                  .with(storeKit1Timeout: 15)
 *                                  .with(usesStoreKit2IfAvailable: true)
 *                                  .build()
 *  Purchases.configure(with: configuration)
 * ```
 */
@objc(RCConfiguration) public final class Configuration: NSObject {

    static let storeKitRequestTimeoutDefault: TimeInterval = 30
    static let networkTimeoutDefault: TimeInterval = 60

    let apiKey: String
    let appUserID: String?
    let observerMode: Bool
    let userDefaults: UserDefaults?
    let storeKit2Setting: StoreKit2Setting
    let dangerousSettings: DangerousSettings?
    let networkTimeout: TimeInterval
    let storeKit1Timeout: TimeInterval
    let platformInfo: Purchases.PlatformInfo?
    let responseVerificationLevel: Signing.ResponseVerificationLevel

    private init(with builder: Builder) {
        Self.verify(apiKey: builder.apiKey)

        self.apiKey = builder.apiKey
        self.appUserID = builder.appUserID
        self.observerMode = builder.observerMode
        self.userDefaults = builder.userDefaults
        self.storeKit2Setting = builder.storeKit2Setting
        self.dangerousSettings = builder.dangerousSettings
        self.storeKit1Timeout = builder.storeKit1Timeout
        self.networkTimeout = builder.networkTimeout
        self.platformInfo = builder.platformInfo
        self.responseVerificationLevel = builder.responseVerificationLevel
    }

    /// Factory method for the ``Configuration/Builder`` object that is required to create a `Configuration`
    @objc public static func builder(withAPIKey apiKey: String) -> Builder {
        return Builder(withAPIKey: apiKey)
    }

    /// The Builder for ```Configuration```.
    @objc(RCConfigurationBuilder) public class Builder: NSObject {

        private static let minimumTimeout: TimeInterval = 5

        private(set) var apiKey: String
        private(set) var appUserID: String?
        private(set) var observerMode: Bool = false
        private(set) var userDefaults: UserDefaults?
        private(set) var storeKit2Setting: StoreKit2Setting = .default
        private(set) var dangerousSettings: DangerousSettings?
        private(set) var networkTimeout = Configuration.networkTimeoutDefault
        private(set) var storeKit1Timeout = Configuration.storeKitRequestTimeoutDefault
        private(set) var platformInfo: Purchases.PlatformInfo?
        private(set) var responseVerificationLevel: Signing.ResponseVerificationLevel = .default

        /**
         * Create a new builder with your API key.
         * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
         */
        @objc public init(withAPIKey apiKey: String) {
            self.apiKey = apiKey
        }

        /// Update your API key.
        @objc public func with(apiKey: String) -> Builder {
            self.apiKey = apiKey
            return self
        }

        /**
         * Set an `appUserID`.
         * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
         * purchases and subscriptions across devices. Pass `nil` or an empty string if you want ``Purchases``
         * to generate this for you.
         *
         * - Note: Best practice is to use a salted hash of your unique app user ids.
         *
         * - Important: Set this property if you have your own user identifiers that you manage.
         */
        @objc public func with(appUserID: String?) -> Builder {
            self.appUserID = appUserID
            return self
        }

        /**
         * Set `observerMode`.
         * - Parameter observerMode: Set this to `true` if you have your own IAP implementation and want to use only
         * RevenueCat's backend. Default is `false`.
         */
        @objc public func with(observerMode: Bool) -> Builder {
            self.observerMode = observerMode
            return self
        }

        /**
         * Set `userDefaults`.
         * - Parameter userDefaults: Custom `UserDefaults` to use
         */
        @objc public func with(userDefaults: UserDefaults) -> Builder {
            self.userDefaults = userDefaults
            return self
        }

        /**
         * Set `usesStoreKit2IfAvailable`.
         * - Parameter usesStoreKit2IfAvailable: opt in using StoreKit 2 on devices that support it.
         * Defaults to  `false`.
         */
        @objc public func with(usesStoreKit2IfAvailable: Bool) -> Builder {
            self.storeKit2Setting = .init(useStoreKit2IfAvailable: usesStoreKit2IfAvailable)
            return self
        }

        /**
         * Set `dangerousSettings`.
         * - Parameter dangerousSettings: Only use if suggested by RevenueCat support team.
         */
        @objc public func with(dangerousSettings: DangerousSettings) -> Builder {
            self.dangerousSettings = dangerousSettings
            return self
        }

        /// Set `networkTimeout`.
        @objc public func with(networkTimeout: TimeInterval) -> Builder {
            self.networkTimeout = clamped(timeout: networkTimeout)
            return self
        }

        /// Set `storeKit1Timeout`.
        @objc public func with(storeKit1Timeout: TimeInterval) -> Builder {
            self.storeKit1Timeout = clamped(timeout: storeKit1Timeout)
            return self
        }

        /// Set `platformInfo`.
        @objc public func with(platformInfo: Purchases.PlatformInfo) -> Builder {
            self.platformInfo = platformInfo
            return self
        }

        /// Set ``Configuration/EntitlementVerificationLevel``
        /// - Note: this requires iOS 13+
        /// - Throws: ``ErrorCode/configurationError`` if the key cannot be loaded
        @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
        @objc internal func with(entitlementVerificationLevel level: EntitlementVerificationLevel) throws -> Builder {
            self.responseVerificationLevel = try Signing.verificationLevel(with: level)
            return self
        }

        /// Generate a ``Configuration`` object given the values configured by this builder.
        @objc public func build() -> Configuration {
            return Configuration(with: self)
        }

        private func clamped(timeout: TimeInterval) -> TimeInterval {
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

// MARK: - Public Keys

internal extension Configuration {

    /// Defines how strict ``EntitlementInfo`` verification ought to be.
    @objc(RCEntitlementVerificationLevel)
    enum EntitlementVerificationLevel: Int {

        /// The SDK will perform no entitlement verification.
        case disabled = 0

        /// The SDK will verify entitlements, but will not fail to parse them if verification failed.
        case informationOnly = 1

        /// The SDK will verify entitlements, and it will throw an error if verification failed.
        case enforced = 2

    }

}

// MARK: - API Key Validation

// Visible for testing
extension Configuration {

    enum APIKeyValidationResult {
        case validApplePlatform
        case otherPlatforms
        case legacy
    }

    static func validate(apiKey: String) -> APIKeyValidationResult {
        if apiKey.hasPrefix(Self.applePlatformKeyPrefix) {
            // Apple key format: "apple_CtDdmbdWBySmqJeeQUTyrNxETUVkajsJ"
            return .validApplePlatform
        } else if apiKey.contains("_") {
            // Other platforms format: "otherplatform_CtDdmbdWBySmqJeeQUTyrNxETUVkajsJ"
            return .otherPlatforms
        } else {
            // Legacy key format: "CtDdmbdWBySmqJeeQUTyrNxETUVkajsJ"
            return .legacy
        }
    }

    fileprivate static func verify(apiKey: String) {
        switch self.validate(apiKey: apiKey) {
        case .validApplePlatform: break
        case .legacy: Logger.debug(Strings.configure.legacyAPIKey)
        case .otherPlatforms: Logger.error(Strings.configure.invalidAPIKey)
        }
    }

    private static let applePlatformKeyPrefix: String = "appl_"

}

// MARK: - Slow Operation Thresholds

extension Configuration {

    /// Thresholds that determine when `TimingUtil` log warnings for slow operations.
    internal enum TimingThreshold: TimingUtil.Duration {

        case productRequest = 3
        case purchase = 7
        case introEligibility = 2

    }

}
