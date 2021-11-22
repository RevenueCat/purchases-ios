//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Purchases+ConfigureIntegrations.swift
//
//  Created by Joshua Liebowitz on 11/21/21.

import Foundation
import SwiftUI

public extension Purchases {

    /**
     * Configures an instance of the Purchases SDK with a specified API key. The instance will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Note: Use this initializer if your app does not have an account system.
     * `Purchases` will generate a unique identifier for the current device and persist it to `NSUserDefaults`.
     * This also affects the behavior of ``Purchases/restoreTransactions(completion:)``.
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     * - Parameter integrations: Which ever services you're using that are supported by our integrations.
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:integrations:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             integrations: [Integration.Type]? = nil) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: nil, integrations: integrations)
    }

    /**
     * Configures an instance of the Purchases SDK with a specified API key and app user ID.
     * The instance will be set as a singleton.
     * You should access the singleton instance using ``Purchases/shared``
     *
     * - Note: Best practice is to use a salted hash of your unique app user ids.
     *
     * - Warning: Use this initializer if you have your own user identifiers that you manage.
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
     * purchases and subscriptions across devices. Pass nil if you want `Purchases` to generate this for you.
     *
     * - Parameter integrations: Which ever services you're using that are supported by our integrations.
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:integrations:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             integrations: [Integration.Type]? = nil) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: false)
    }

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults. Use this constructor if you want to
     * sync status across a shared container, such as between a host app and an extension. The instance of the
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases.shared``
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
     * purchases and subscriptions across devices. Pass nil if you want `Purchases` to generate this for you.
     *
     * - Parameter observerMode: Set this to `true` if you have your own IAP implementation and want to use only
     * RevenueCat's backend. Default is `false`.
     *
     * - Parameter integrations: Which ever services you're using that are supported by our integrations.
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:integrations:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             integrations: [Integration.Type]? = nil) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: observerMode, userDefaults: nil)
    }

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults. Use this constructor if you want to
     * sync status across a shared container, such as between a host app and an extension. The instance of the
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases.shared``
     *
     * - Parameter apiKey: The API Key generated for your app from https://app.revenuecat.com/
     *
     * - Parameter appUserID: The unique app user id for this user. This user id will allow users to share their
     * purchases and subscriptions across devices. Pass nil if you want `Purchases` to generate this for you.
     *
     * - Parameter observerMode: Set this to `true` if you have your own IAP implementation and want to use only
     * RevenueCat's backend. Default is `false`.
     *
     * - Parameter userDefaults: Custom userDefaults to use
     *
     * - Parameter integrations: Which ever services you're using that are supported by our integrations.
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:integrations:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?,
                                             integrations: [Integration.Type]? = nil) -> Purchases {
        configure(apiKey: apiKey,
                  appUserID: appUserID,
                  observerMode: observerMode,
                  userDefaults: userDefaults,
                  platformFlavor: nil,
                  platformFlavorVersion: nil,
                  integrations: integrations)
    }

    /**
     * Returns a configured integration object if it exists.
     *
     * - Parameter integrationType: Integration class that you wish to use
     *
     */
    func getIntegration<T>(for integrationType: T.Type) -> T? where T: Integration {
        let configuredIntegration = self.configuredIntegrations[integrationType.networkName]
        if configuredIntegration == nil {
            Logger.warn(
                """
                Attempt to get integration: \(integrationType.networkName), but it wasn't found, please ensure you call
                 configureWithAPIKey:appUserID:integrations:
                """
            )
        }
        return configuredIntegration as? T
    }

    /**
     * Returns a configured integration object if it exists.
     * - Note: This is meant for ObjC use.
     *
     * - Parameter forIntegrationType: Integration class that you wish to use
     */
    @objc func getIntegration(integrationType: Integration.Type) -> Any? {
        let configuredIntegration = self.configuredIntegrations[integrationType.networkName]
        if configuredIntegration == nil {
            Logger.warn(
                """
                Attempt to get integration: \(integrationType.networkName), but it wasn't found, please ensure you call
                 configureWithAPIKey:appUserID:integrations:
                """
            )
        }
        return configuredIntegration
    }

    internal func configureIntegrations() {
        self.configuredIntegrations = [:]
        guard let integrations = self.integrations else {
            return
        }

        integrations.forEach { integrationClass in
            let integrationKey = integrationClass.networkName

            guard self.configuredIntegrations[integrationKey] == nil else {
                fatalError("Integration for \(integrationClass.networkName) already exists, cannot add a duplicate.")
            }

            let initializedIntegration = integrationClass.configure(
                subscriberAttributionSetter: self.subscriberAttributesManager,
                appUserIdentifier: self.identityManager
            )

            self.configuredIntegrations[integrationKey] = initializedIntegration
        }
    }

}
