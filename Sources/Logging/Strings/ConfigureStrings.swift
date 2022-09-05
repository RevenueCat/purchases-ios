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

    case adsupport_not_imported

    case application_active

    case configuring_purchases_proxy_url_set(url: String)

    case debug_enabled

    case store_kit_2_enabled

    case delegate_set

    case purchase_instance_already_set

    case initial_app_user_id(isSet: Bool)

    case no_singleton_instance

    case sdk_version(String)

    case bundle_id(String)

    case legacyAPIKey

    case invalidAPIKey

    case autoSyncPurchasesDisabled

}

extension ConfigureStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case .adsupport_not_imported:
            return "AdSupport framework not imported. Attribution data incomplete."
        case .application_active:
            return "applicationDidBecomeActive"
        case .configuring_purchases_proxy_url_set(let url):
            return "Purchases is being configured using a proxy for RevenueCat " +
                " with URL: \(url)"
        case .debug_enabled:
            return "Debug logging enabled"
        case .store_kit_2_enabled:
            return "StoreKit 2 support enabled"
        case .delegate_set:
            return "Delegate set"
        case .purchase_instance_already_set:
            return "Purchases instance already set. Did you mean to configure " +
                "two Purchases objects?"
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
        }
    }

}
