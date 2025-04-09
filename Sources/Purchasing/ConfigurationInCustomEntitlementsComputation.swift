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

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION

// swiftlint:disable type_name
/**
 * ``ConfigurationInCustomEntitlementsComputation`` can be used when configuring the ``Purchases`` instance.
 * It is not required to be used, but highly recommended. This class follows a builder pattern.
 *
 * To configure your `Purchases` instance using this object, follow these steps.
 *
 * **Steps:**
 * 1. Call ``ConfigurationInCustomEntitlementsComputation/builder(withAPIKey:)``
 *  To obtain a ``ConfigurationInCustomEntitlementsComputation/Builder`` object.
 * 2. Set this builder's properties using the "`with(`" functions.
 * 3. Call ``ConfigurationInCustomEntitlementsComputation/Builder/build()`` to obtain the
 *  `ConfigurationInCustomEntitlementsComputation` object.
 * 4. Pass the `ConfigurationInCustomEntitlementsComputation` object into
 *  ``Purchases/configureInCustomEntitlementsComputationMode(with:)``.
 *
 * ```swift
 * let configuration = ConfigurationInCustomEntitlementsComputation.Builder(withAPIKey: "MyKey",
 *                                                                          appUserID: "SomeAppUserID).build()
 *  Purchases.configure(with: configuration)
 * ```
 */
public final class ConfigurationInCustomEntitlementsComputation: NSObject {

    static let storeKitRequestTimeoutDefault: TimeInterval = 30
    static let networkTimeoutDefault: TimeInterval = 60

    let apiKey: String
    let appUserID: String?
    internal let observerMode: Bool
    internal let userDefaults: UserDefaults?
    let storeKitVersion: StoreKitVersion
    internal let dangerousSettings: DangerousSettings?
    internal let networkTimeout: TimeInterval
    internal let storeKit1Timeout: TimeInterval
    internal let platformInfo: Purchases.PlatformInfo?
    internal let responseVerificationMode: Signing.ResponseVerificationMode
    let showStoreMessagesAutomatically: Bool
    internal let diagnosticsEnabled: Bool

    private init(with builder: Builder) {
        Self.verify(apiKey: builder.apiKey)

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
    }

    /// Factory method for the ``Configuration/Builder`` object that is required to create a `Configuration`
    @objc public static func builder(withAPIKey apiKey: String, appUserID: String) -> Builder {
        return Builder(withAPIKey: apiKey, appUserID: appUserID)
    }

    /// The Builder for ```ConfigurationInCustomEntitlementsComputation```.
    public class Builder: NSObject {

        private static let minimumTimeout: TimeInterval = 5

        private(set) var apiKey: String
        private(set) var appUserID: String?
        internal var observerMode: Bool {
            switch purchasesAreCompletedBy {
            case .revenueCat:
                return false
            case .myApp:
                return true
            }
        }
        private(set) internal var purchasesAreCompletedBy: PurchasesAreCompletedBy = .revenueCat
        private(set) internal var userDefaults: UserDefaults?
        private(set) internal var dangerousSettings: DangerousSettings? = DangerousSettings(
            customEntitlementComputation: true
        )
        private(set) internal var networkTimeout = Configuration.networkTimeoutDefault
        private(set) internal var storeKit1Timeout = Configuration.storeKitRequestTimeoutDefault
        private(set) internal var platformInfo: Purchases.PlatformInfo?
        private(set) internal var responseVerificationMode: Signing.ResponseVerificationMode = .default
        private(set) var showStoreMessagesAutomatically: Bool = true
        private(set) internal var diagnosticsEnabled: Bool = false
        private(set) var storeKitVersion: StoreKitVersion = .defaultForCustomEntitlementComputation

        /**
         * Create a new builder with your API key.
         * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
         */
        @objc public init(withAPIKey apiKey: String, appUserID: String) {
            self.apiKey = apiKey
            self.appUserID = appUserID
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

        @available(*, deprecated, message: """
        The appUserID passed to configure is a constant string known at compile time.
        This is likely a programmer error. This ID is used to identify the current user.
        See https://docs.revenuecat.com/docs/user-ids for more information.
        """)
        // swiftlint:disable:next missing_docs
        public func with(appUserID: StaticString) -> ConfigurationInCustomEntitlementsComputation.Builder {
            Logger.warn(Strings.identity.logging_in_with_static_string)
            return self.with(appUserID: "\(appUserID)")
        }

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

        /// Generate a ``Configuration`` object given the values configured by this builder.
        @objc public func build() -> ConfigurationInCustomEntitlementsComputation {
            return ConfigurationInCustomEntitlementsComputation(with: self)
        }

    }

}

// swiftlint:enable type_name

// MARK: - API Key Validation

// Visible for testing
extension ConfigurationInCustomEntitlementsComputation {

    enum APIKeyValidationResult {
        case validApplePlatform
        case otherPlatforms
        case legacy
    }

    static func validate(apiKey: String) -> APIKeyValidationResult {
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

    fileprivate static func verify(apiKey: String) {
        switch self.validate(apiKey: apiKey) {
        case .validApplePlatform: break
        case .legacy: Logger.debug(Strings.configure.legacyAPIKey)
        case .otherPlatforms: Logger.error(Strings.configure.invalidAPIKey)
        }
    }

    private static let applePlatformKeyPrefixes: Set<String> = ["appl_", "mac_"]

}

#endif
