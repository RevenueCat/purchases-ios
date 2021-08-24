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
class ConfigureStrings {

    var adsupport_not_imported: String { "AdSupport framework not imported. Attribution data incomplete." }
    var application_active: String { "applicationDidBecomeActive" }
    var configuring_purchases_proxy_url_set: String {
        "Purchases is being configured using a proxy for RevenueCat with URL: %@"
    }
    var debug_enabled: String { "Debug logging enabled" }
    var delegate_set: String { "Delegate set" }
    var purchase_instance_already_set: String {
        "Purchases instance already set. Did you mean to configure two Purchases objects?"
    }
    var initial_app_user_id: String { "Initial App User ID - %@" }
    var no_singleton_instance: String {
        "There is no singleton instance. Make sure you configure Purchases before trying to get the default instance." +
            " More info here: https://errors.rev.cat/configuring-sdk"
    }
    var sdk_version: String { "SDK Version - %@" }

}
