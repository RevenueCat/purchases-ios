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

// swiftlint:disable file_length

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
    let storeKitVersion: StoreKitVersion
    let dangerousSettings: DangerousSettings?
    let networkTimeout: TimeInterval
    let storeKit1Timeout: TimeInterval
    let platformInfo: Purchases.PlatformInfo?
    let responseVerificationMode: Signing.ResponseVerificationMode
    let showStoreMessagesAutomatically: Bool
    let preferredLocale: String?
    let automaticDeviceIdentifierCollectionEnabled: Bool
    internal let diagnosticsEnabled: Bool

    private init(with builder: Builder) {
        self.apiKey = builder.apiKey
        self.appUserID = builder.appUserID
        self.observerMode = builder.observerMode
        self.userDefaults = builder.userDefaults
        self.storeKitVersion = builder.storeKitVersion
        self.dangerousSettings = builder.dangerousSettings
        self.storeKit1Timeout = builder.storeKit1Timeout
        self.networkTimeout = builder.networkTimeout
        self.platformInfo = builder.platformInfo
        self.responseVerificationMode = builder.responseVerificationMode
        self.showStoreMessagesAutomatically = builder.showStoreMessagesAutomatically
        self.diagnosticsEnabled = builder.diagnosticsEnabled
        self.preferredLocale = builder.preferredLocale
        self.automaticDeviceIdentifierCollectionEnabled = builder.automaticDeviceIdentifierCollectionEnabled
    }

    #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

    /// Factory method for the ``Configuration/Builder`` object that is required to create a `Configuration`
    @objc public static func builder(withAPIKey apiKey: String) -> Builder {
        return Builder(withAPIKey: apiKey)
    }

    #else

    /// Factory method for the ``Configuration/Builder`` object that is required to create a `Configuration`
    @objc public static func builder(withAPIKey apiKey: String, appUserID: String) -> Builder {
        return Builder(withAPIKey: apiKey, appUserID: appUserID)
    }

    #endif

    /// The Builder for ```Configuration```.
    @objc(RCConfigurationBuilder) public class Builder: NSObject {

        private static let minimumTimeout: TimeInterval = 5

        private(set) var apiKey: String
        private(set) var appUserID: String?
        var observerMode: Bool {
            switch purchasesAreCompletedBy {
            case .revenueCat:
                return false
            case .myApp:
                return true
            }
        }
        private(set) var purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat
        private(set) var userDefaults: UserDefaults?
        private(set) var dangerousSettings: DangerousSettings?
        private(set) var networkTimeout = Configuration.networkTimeoutDefault
        private(set) var storeKit1Timeout = Configuration.storeKitRequestTimeoutDefault
        private(set) var platformInfo: Purchases.PlatformInfo?
        private(set) var responseVerificationMode: Signing.ResponseVerificationMode = .default
        private(set) var showStoreMessagesAutomatically: Bool = true
        private(set) var diagnosticsEnabled: Bool = false
        private(set) var storeKitVersion: StoreKitVersion = .default

        /// The preferred locale for the requests.
        ///
        /// This locale is included in all requests made by `HTTPClient`.
        private(set) var preferredLocale: String?
        private(set) var automaticDeviceIdentifierCollectionEnabled: Bool = true

        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

        /**
         * Create a new builder with your API key.
         * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
         */
        @objc public init(withAPIKey apiKey: String) {
            self.apiKey = apiKey
        }

        #else

        /**
         * Create a new builder with your API key.
         * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
         */
        @objc public init(withAPIKey apiKey: String, appUserID: String) {
            self.apiKey = apiKey
            self.appUserID = appUserID
            self.dangerousSettings = DangerousSettings(customEntitlementComputation: true)
        }

        #endif

        /// Update your API key.
        @objc public func with(apiKey: String) -> Builder {
            self.apiKey = apiKey
            return self
        }

        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
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

        @available(*, deprecated, message: """
        The appUserID passed to logIn is a constant string known at compile time.
        This is likely a programmer error. This ID is used to identify the current user.
        See https://docs.revenuecat.com/docs/user-ids for more information.
        """)
        // swiftlint:disable:next missing_docs
        public func with(appUserID: StaticString) -> Configuration.Builder {
            Logger.warn(Strings.identity.logging_in_with_static_string)
            return self.with(appUserID: "\(appUserID)")
        }

        /**
         * Set `purchasesAreCompletedBy`.
         * - Parameter purchasesAreCompletedBy: Set this to ``PurchasesAreCompletedBy/myApp``
         * if you have your own IAP implementation and want to use only RevenueCat's backend. 
         * Default is ``PurchasesAreCompletedBy/revenueCat``.
         * - Parameter storeKitVersion: Set the StoreKit version you're using to make purchases.
         */
        @objc public func with(
            purchasesAreCompletedBy: PurchasesAreCompletedBy,
            storeKitVersion: StoreKitVersion
        ) -> Configuration.Builder {
            self.purchasesAreCompletedBy = purchasesAreCompletedBy
            self.storeKitVersion = storeKitVersion
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

        #endif

        /// Set `showStoreMessagesAutomatically`. Enabled by default.
        /// If enabled, if the user has billing issues, has yet to accept a price increase consent, is eligible for a
        /// win-back offer, or there are other messages from StoreKit, they will be displayed automatically when
        /// the app is initialized.
        ///
        /// If you want to disable this behavior so that you can customize when these messages are shown, make sure
        /// you configure the SDK as early as possible in the app's lifetime, otherwise messages will be displayed
        /// automatically.
        /// Then use the ``Purchases/showStoreMessages(for:)`` method to display the messages.
        /// More information:  https://rev.cat/storekit-message
        /// - Important: Set this property only if you're using Swift. If you're using ObjC, you won't be able to call
        /// the related methods
        @objc public func with(showStoreMessagesAutomatically: Bool) -> Builder {
            self.showStoreMessagesAutomatically = showStoreMessagesAutomatically
            return self
        }

        #if !ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

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
        @objc public func with(entitlementVerificationMode mode: EntitlementVerificationMode) -> Builder {
            self.responseVerificationMode = Signing.verificationMode(with: mode)
            return self
        }

        /// Enabling diagnostics will send some performance and debugging information from the SDK to our servers.
        /// Examples of this information include response times, cache hits or error codes.
        /// This information will be anonymous so it can't be traced back to the end-user
        /// 
        /// Defaults to `false`
        ///
        @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
        @objc public func with(diagnosticsEnabled: Bool) -> Builder {
            self.diagnosticsEnabled = diagnosticsEnabled
            return self
        }

        #endif

        /// Set ``StoreKitVersion``.
        ///
        /// Defaults to ``StoreKitVersion/default`` which lets the SDK select
        /// the most appropriate version of StoreKit. Currently defaults to StoreKit 2.
        ///
        /// - Note: StoreKit 2 is only available on iOS 15+. StoreKit 1 will be used for previous iOS versions
        /// regardless of this setting.
        ///
        /// ### Related Symbols
        /// - ``StoreKitVersion``
        @objc public func with(storeKitVersion version: StoreKitVersion) -> Builder {
            self.storeKitVersion = version
            return self
        }

        /// Set `automaticDeviceIdentifierCollectionEnabled`. This is enabled by default.
        ///
        /// Enable this setting to allow the collection of identifiers when setting the identifier for an
        /// attribution network. For example, when calling``Purchases/setAdjustID(_:)``
        /// or ``Purchases/setAppsflyerID(_:)``, the SDK would collect the device identifiers like
        /// IDFA, IDFV or IP, if available, and send them to RevenueCat.
        /// This is required by some attribution networks to attribute installs and re-installs.
        ///
        /// Enabling this setting does NOT mean we will always collect the identifiers. We will only do so when
        /// setting an attribution network ID and the user has not limited tracking on their device.
        ///
        /// With this option disabled you can still collect device identifiers
        /// by calling ``Purchases/collectDeviceIdentifiers()``
        @objc public func with(automaticDeviceIdentifierCollectionEnabled: Bool) -> Builder {
            self.automaticDeviceIdentifierCollectionEnabled = automaticDeviceIdentifierCollectionEnabled
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

        /// Overrides the preferred locale for RevenueCatUI components.
        ///
        /// - Parameter preferredUILocaleOverride: A locale string in the format "language_region" (e.g., "en_US").
        ///
        /// Defaults to `nil`, which means using the default user locale for RevenueCatUI components.
        public func with(preferredUILocaleOverride: String?) -> Builder {
            self.preferredLocale = preferredUILocaleOverride
            return self
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

        /// An API key used for the Simulated Store.
        ///
        /// Note that "Simulated Store" is the internal name of the "Test Store".
        case simulatedStore
        case otherPlatforms
        case legacy
    }

    static func validateAndLog(apiKey: String) -> APIKeyValidationResult {
        let validationResult = self.validate(apiKey: apiKey)
        validationResult.logIfNeeded()
        return validationResult
    }

    private static let applePlatformKeyPrefixes: Set<String> = ["appl_", "mac_"]
    private static let simulatedStoreKeyPrefix = "test_"

    private static func validate(apiKey: String) -> APIKeyValidationResult {
        if apiKey.hasPrefix(simulatedStoreKeyPrefix) {
            // Simulated Store key format: "test_CtDdmbdWBySmqJeeQUTyrNxETUVkajsJ"
            return .simulatedStore
        }

        if applePlatformKeyPrefixes.contains(where: { prefix in apiKey.hasPrefix(prefix) }) {
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
}

extension Configuration.APIKeyValidationResult {

    fileprivate func logIfNeeded() {
        switch self {
        case .validApplePlatform: break
        case .simulatedStore: Logger.warn(Strings.configure.simulatedStoreAPIKey)
        case .legacy: Logger.debug(Strings.configure.legacyAPIKey)
        case .otherPlatforms: Logger.error(Strings.configure.invalidAPIKey)
        }
    }

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

extension Configuration.APIKeyValidationResult {

    func checkForSimulatedStoreAPIKeyInRelease(systemInfo: SystemInfo, apiKey: String) {
        #if !DEBUG
        guard self == .simulatedStore, !systemInfo.dangerousSettings.uiPreviewMode else {
            return
        }

        let redactedApiKey = apiKey.asRedactedAPIKey

        // In release builds, we intentionally crash to prevent submitting an app with a Test Store API key.
        //
        // Also note that developing with a Test Store API key isn't supported when adding the SDK dependency
        // as an XCFramework, since the XCFramework is built using the Release configuration.
        Task {
            let errorMessage = "[RevenueCat]: Test Store API key used in Release build: \(redactedApiKey). " +
            "Please configure the App Store app on the RevenueCat dashboard and use its corresponding Apple API key " +
            "before releasing. Visit https://rev.cat/sdk-test-store to learn more."

            Logger.error(errorMessage)

            let uiHelper = DefaultSimulatedStorePurchaseUI(systemInfo: systemInfo)
            await uiHelper.showTestKeyInReleaseAlert(redactedApiKey: redactedApiKey)

            fatalError(errorMessage)
        }
        #endif
    }
}
