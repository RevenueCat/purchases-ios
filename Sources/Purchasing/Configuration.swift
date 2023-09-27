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
 * 1. Call ``Configuration/builder(withAPIKey:)`` To obtain a ``Configuration/Builder`` object.
 * 2. Set this builder's properties using the "`with(`" functions.
 * 3. Call ``Configuration/Builder/build()`` to obtain the `Configuration` object.
 * 4. Pass the `Configuration` object into ``Purchases/configure(with:)-6oipy``.
 *
 * ```swift
 * let configuration = Configuration.Builder(withAPIKey: "MyKey")
 *                                  .with(appUserID: "SomeAppUserID")
 *                                  .with(userDefaults: myUserDefaults)
 *                                  .with(networkTimeout: 15)
 *                                  .with(storeKit1Timeout: 15)
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
    let responseVerificationMode: Signing.ResponseVerificationMode
    let showStoreKitMessagesAutomatically: Bool

    private init(with builder: Builder) {
        Self.verify(apiKey: builder.apiKey)
        Self.verify(observerMode: builder.observerMode, storeKit2Setting: builder.storeKit2Setting)

        self.apiKey = builder.apiKey
        self.appUserID = builder.appUserID
        self.observerMode = builder.observerMode
        self.userDefaults = builder.userDefaults
        self.storeKit2Setting = builder.storeKit2Setting
        self.dangerousSettings = builder.dangerousSettings
        self.storeKit1Timeout = builder.storeKit1Timeout
        self.networkTimeout = builder.networkTimeout
        self.platformInfo = builder.platformInfo
        self.responseVerificationMode = builder.responseVerificationMode
        self.showStoreKitMessagesAutomatically = builder.showStoreKitMessagesAutomatically
    }

    /// Factory method for the ``Configuration/Builder`` object that is required to create a `Configuration`
    @objc public static func builder(withAPIKey apiKey: String) -> Builder {
        return Builder(withAPIKey: apiKey)
    }

    /// The Builder for ```Configuration```.
    @objc(RCConfigurationBuilder) public class Builder: NSObject {

        // made internal to access it in Deprecations.swift
        var storeKit2Setting: StoreKit2Setting = .default

        private static let minimumTimeout: TimeInterval = 5

        private(set) var apiKey: String
        private(set) var appUserID: String?
        private(set) var observerMode: Bool = false
        private(set) var userDefaults: UserDefaults?
        private(set) var dangerousSettings: DangerousSettings?
        private(set) var networkTimeout = Configuration.networkTimeoutDefault
        private(set) var storeKit1Timeout = Configuration.storeKitRequestTimeoutDefault
        private(set) var platformInfo: Purchases.PlatformInfo?
        private(set) var responseVerificationMode: Signing.ResponseVerificationMode = .default
        private(set) var showStoreKitMessagesAutomatically: Bool = true

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
        @_disfavoredOverload
        @objc public func with(appUserID: String?) -> Builder {
            self.appUserID = appUserID
            return self
        }

        // swiftlint:disable:next missing_docs
        public func with(appUserID: StaticString) -> Configuration.Builder {
            Logger.warn(Strings.identity.logging_in_with_static_string)
            return self.with(appUserID: "\(appUserID)")
        }

        /**
         * Set `observerMode`.
         * - Parameter observerMode: Set this to `true` if you have your own IAP implementation and want to use only
         * RevenueCat's backend. Default is `false`.
         *
         * - Warning: This assumes your IAP implementation uses StoreKit 1.
         * Observer mode is not compatible with StoreKit 2.
         */
        @objc public func with(observerMode: Bool) -> Configuration.Builder {
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

        /// Set `showStoreKitMessagesAutomatically`. Enabled by default. If you want to disable, make sure
        /// you're configuring the SDK during the `didFinishLaunchingWithOptions` delegate call.
        @objc public func with(showStoreKitMessagesAutomatically: Bool) -> Builder {
            self.showStoreKitMessagesAutomatically = showStoreKitMessagesAutomatically
            return self
        }

        /// Set ``Configuration/EntitlementVerificationMode``.
        ///
        /// Defaults to ``Configuration/EntitlementVerificationMode/disabled``.
        ///
        /// The result of the verification can be obtained from ``EntitlementInfos/verification`` or
        /// ``EntitlementInfo/verification``.
        /// 
        /// - Note: This feature requires iOS 13+.
        /// - Warning:  When changing from ``Configuration/EntitlementVerificationMode/disabled``
        /// to ``Configuration/EntitlementVerificationMode/informational``
        /// the SDK will clear the ``CustomerInfo`` cache.
        /// This means that users will need to connect to the internet to get back their entitlements.
        ///
        /// ### Related Articles
        /// - [Documentation](https://rev.cat/trusted-entitlements)
        ///
        /// ### Related Symbols
        /// - ``Configuration/EntitlementVerificationMode``
        /// - ``VerificationResult``
        @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
        @objc public func with(entitlementVerificationMode mode: EntitlementVerificationMode) -> Builder {
            self.responseVerificationMode = Signing.verificationMode(with: mode)
            return self
        }

        /// Generate a ``Configuration`` object given the values configured by this builder.
        @objc public func build() -> Configuration {
            return Configuration(with: self)
        }

        private func clamped(timeout: TimeInterval) -> TimeInterval {
            guard timeout >= Self.minimumTimeout else {
                Logger.warn(
                    Strings.configure.timeout_lower_than_minimum(
                        timeout: timeout,
                        minimum: Self.minimumTimeout
                    )
                )
                return Self.minimumTimeout
            }

            return timeout
        }

    }

}

// MARK: - Public Keys

extension Configuration {

    /// Defines how strict ``EntitlementInfo`` verification ought to be.
    ///
    /// ### Related Articles
    /// - [Documentation](https://rev.cat/trusted-entitlements)
    ///
    /// ### Related Symbols
    /// - ``VerificationResult``
    /// - ``Configuration/Builder/with(entitlementVerificationMode:)``
    /// - ``EntitlementInfos/verification``
    @objc(RCEntitlementVerificationMode)
    public enum EntitlementVerificationMode: Int {

        /// The SDK will not perform any entitlement verification.
        case disabled = 0

        /// Enable entitlement verification.
        ///
        /// If verification fails, this will be indicated with ``VerificationResult/failed``
        /// but parsing will not fail.
        /// 
        /// This can be useful if you want to handle validation failures but still grant access.
        case informational = 1

        /// Enable entitlement verification.
        ///
        /// If verification fails when fetching ``CustomerInfo`` and/or ``EntitlementInfos``
        /// ``ErrorCode/signatureVerificationFailed`` will be thrown.
        @available(*, unavailable, message: "This will be supported in a future release")
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

    fileprivate static func verify(observerMode: Bool, storeKit2Setting: StoreKit2Setting) {
        if observerMode, storeKit2Setting.usesStoreKit2IfAvailable {
            Logger.warn(Strings.configure.observer_mode_with_storekit2)
        }
    }

    private static let applePlatformKeyPrefix: String = "appl_"

}

// MARK: - Slow Operation Thresholds

extension Configuration {

    /// Thresholds that determine when `TimingUtil` log warnings for slow operations.
    internal enum TimingThreshold: TimingUtil.Duration {

        case productRequest = 3
        case introEligibility = 2
        case purchasedProducts = 1

    }

}
