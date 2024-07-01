//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConfigureStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

// swiftlint:disable identifier_name
enum ConfigureStrings {

    case purchases_init(Purchases, EitherPaymentQueueWrapper)

    case purchases_deinit(Purchases)

    case adsupport_not_imported

    case application_foregrounded

    case configuring_purchases_proxy_url_set(url: String)

    case debug_enabled

    case observer_mode_enabled

    case response_verification_mode(Signing.ResponseVerificationMode)

    case storekit_version(StoreKitVersion)

    case delegate_set

    case purchase_instance_already_set

    case initial_app_user_id(isSet: Bool)

    case no_singleton_instance

    case sdk_version(String)

    case bundle_id(String)

    case system_version(String)

    case is_simulator(Bool)

    case legacyAPIKey

    case invalidAPIKey

    case autoSyncPurchasesDisabled

    case using_custom_user_defaults

    case using_user_defaults_standard

    case using_user_defaults_suite_name

    case public_key_could_not_be_found(fileName: String)

    case custom_entitlements_computation_enabled

    case custom_entitlements_computation_enabled_but_no_app_user_id

    case timeout_lower_than_minimum(timeout: TimeInterval, minimum: TimeInterval)

    case sk2_required_for_swiftui_paywalls

    case record_purchase_requires_purchases_made_by_my_app

    case sk2_required

    case sk2_invalid_inapp_purchase_key
}

extension ConfigureStrings: LogMessage {

    var description: String {
        switch self {
        case let .purchases_init(purchases, wrapper):
            return "Purchases.init: created new Purchases instance: " +
            "\(Strings.objectDescription(purchases))\nStoreKit Wrapper: \(wrapper)"
        case let .purchases_deinit(purchases):
            return "Purchases.deinit: " +
            "\(Strings.objectDescription(purchases))"
        case .adsupport_not_imported:
            return "AdSupport framework not imported. Attribution data incomplete."
        case .application_foregrounded:
            return "applicationWillEnterForeground"
        case .configuring_purchases_proxy_url_set(let url):
            return "Purchases is being configured using a proxy for RevenueCat " +
                "with URL: \(url)"
        case .debug_enabled:
            return "Debug logging enabled"
        case .observer_mode_enabled:
            return "Purchases is configured with purchasesAreCompletedBy set to .myApp"
        case let .response_verification_mode(mode):
            switch mode {
            case .disabled:
                return "Purchases is configured with response verification disabled"
            case .informational:
                return "Purchases is configured with informational response verification"
            case .enforced:
                return "Purchases is configured with enforced response verification"
            }
        case let .storekit_version(version):
            return "Purchases is configured with StoreKit version \(version)"
        case .delegate_set:
            return "Delegate set"
        case .purchase_instance_already_set:
            return "Purchases instance already set. Did you mean to configure two Purchases objects?"
        case .initial_app_user_id(let isSet):
            return isSet
                ? "Initial App User ID set"
                : "No initial App User ID"
        case .no_singleton_instance:
            return "There is no singleton instance. Make sure you configure Purchases before " +
                "trying to get the default instance. More info here: https://errors.rev.cat/configuring-sdk"
        case let .sdk_version(sdkVersion):
            return "SDK Version - \(sdkVersion)"
        case let .bundle_id(bundleID):
            return "Bundle ID - \(bundleID)"
        case let .system_version(osVersion):
            return "System Version - \(osVersion)"
        case let .is_simulator(isSimulator):
            return isSimulator
                ? "Using a simulator. Ensure you have a StoreKit Config " +
                "file set up before trying to fetch products or make purchases.\n" +
                "See https://errors.rev.cat/testing-in-simulator for more details."
                : "Not using a simulator."
        case .legacyAPIKey:
            return "Looks like you're using a legacy API key.\n" +
            "This is still supported, but it's recommended to migrate to using platform-specific API key, " +
            "which should look like 'appl_1a2b3c4d5e6f7h'.\n" +
            "See https://rev.cat/auth for more details."
        case .invalidAPIKey:
            return "The specified API Key is not recognized.\n" +
            "Ensure that you are using the public app-specific API key, " +
            " which should look like 'appl_1a2b3c4d5e6f7h'.\n" +
            "See https://rev.cat/auth for more details."

        case .autoSyncPurchasesDisabled:
            return "Automatic syncing of purchases has been disabled. \n" +
            "RevenueCat won’t observe the StoreKit queue, and it will not sync any purchase \n" +
            "automatically. Call syncPurchases whenever a new transaction is completed so the \n" +
            "receipt is sent to RevenueCat’s backend. Consumables disappear from the receipt \n" +
            "after the transaction is finished, so make sure purchases are synced before \n" +
            "finishing any consumable transaction, otherwise RevenueCat won’t register the \n" +
            "purchase."

        case .using_custom_user_defaults:
            return "Configuring SDK using provided UserDefaults."

        case .using_user_defaults_standard:
            return "Configuring SDK using UserDefaults.standard because we found existing data in it."

        case .using_user_defaults_suite_name:
            return "Configuring SDK using RevenueCat's UserDefaults suite."

        case let .public_key_could_not_be_found(fileName):
            return "Could not find public key '\(fileName)'"

        case .custom_entitlements_computation_enabled:
            return "Entering customEntitlementComputation mode. CustomerInfo cache will not be " +
            "automatically fetched. Anonymous user IDs will be disallowed, logOut will be disabled, " +
            "and the PurchasesDelegate's customerInfo listener will only get called after a receipt is posted, " +
            "getCustomerInfo is called or logIn is called."

        case .custom_entitlements_computation_enabled_but_no_app_user_id:
            return "customEntitlementComputation mode is enabled, but appUserID is nil. " +
            "When using customEntitlementComputation, you must set the appUserID to prevent anonymous IDs from " +
            "being generated."

        case let .timeout_lower_than_minimum(timeout, minimum):
            return """
                    Timeout value: \(timeout) is lower than the minimum, setting it
                    to the mimimum: (\(minimum))
                    """

        case .sk2_required_for_swiftui_paywalls:
            return "Purchases is not configured with StoreKit 2 enabled. This is required in order to detect " +
            "transactions coming from SwiftUI paywalls. You must use `.with(storeKitVersion: .storeKit2)` " +
            "when configuring the SDK."

        case .record_purchase_requires_purchases_made_by_my_app:
            return "Attempted to manually handle transactions with purchasesAreCompletedBy not set to .myApp. " +
            "You must use `.with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)` " +
            "when configuring the SDK."

        case .sk2_required:
            return "StoreKit 2 must be enabled. You must use `.with(storeKitVersion: .storeKit2)` " +
            "when configuring the SDK."

        case .sk2_invalid_inapp_purchase_key:
            return "Failed to post the transaction to RevenueCat's backend because your Apple In-App Purchase Key is " +
            "invalid or not present. This error is thrown only in debug builds; in production, it will fail " +
            "silently. You must configure an In-App Purchase Key. Please see " +
            "https://rev.cat/in-app-purchase-key-configuration for more info."
        }
    }

    var category: String { return "configure" }

}
