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

    case delegate_set

    case purchase_instance_already_set

    case initial_app_user_id(appUserID: String?)

    case no_singleton_instance

    case sdk_version(sdkVersion: String)
    
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
        case .delegate_set:
            return "Delegate set"
        case .purchase_instance_already_set:
            return "Purchases instance already set. Did you mean to configure " +
                "two Purchases objects?"
        case .initial_app_user_id(let appUserID):
            return "Initial App User ID - \(appUserID ?? "nil appUserID")"
        case .no_singleton_instance:
            return "There is no singleton instance. Make sure you configure Purchases before " +
                "trying to get the default instance. More info here: https://errors.rev.cat/configuring-sdk"
        case .sdk_version(let sdkVersion):
            return "SDK Version - \(sdkVersion)"
        }
    }

}
