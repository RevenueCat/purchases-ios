//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchasesConfigProvider.swift
//
//  Created by Antonio Pallares on 21/9/26.

import Foundation

protocol ExternalPurchasesConfigProviderType {

    /// The storefronts where an external purchase may be offered even though the store says its external
    /// purchase flow does not apply, as ISO 3166-1 alpha-3 codes.
    ///
    /// Empty when the policy cannot be read, which offers the purchase nowhere rather than everywhere.
    func storefrontsAllowedWithoutStoreEligibility() async -> Set<String>

    /// Whether this app config reports its external purchases to Apple with a token.
    ///
    /// `false` when the policy cannot be read: a token obliges a report, so one is only minted where the
    /// backend says so.
    func reportsTokensToTheAppStore() async -> Bool

}

/// The topic-specific front door for external purchases, reading through `RemoteConfigManager`'s
/// `external_purchases` topic.
///
/// The policy is inline item metadata rather than a blob: it is a handful of country codes that every read
/// needs in full.
final class ExternalPurchasesConfigProvider: ExternalPurchasesConfigProviderType {

    private let manager: RemoteConfigManagerType

    init(manager: RemoteConfigManagerType) {
        self.manager = manager
    }

    func storefrontsAllowedWithoutStoreEligibility() async -> Set<String> {
        guard let topic = await self.manager.topic(.externalPurchases) else {
            Logger.debug(Strings.remoteConfig.externalPurchasesPolicyUnavailable)
            return []
        }

        guard let item = topic[Self.appStoreItemKey],
              case let .array(storefronts)? = item.content[Self.allowedStorefrontsKey] else {
            Logger.debug(Strings.remoteConfig.externalPurchasesPolicyWithoutStorefronts)
            return []
        }

        return Set(storefronts.compactMap { storefront in
            guard case let .string(countryCode) = storefront else { return nil }

            return countryCode.uppercased()
        })
    }

    func reportsTokensToTheAppStore() async -> Bool {
        guard let topic = await self.manager.topic(.externalPurchases) else {
            Logger.debug(Strings.remoteConfig.externalPurchasesPolicyUnavailable)
            return false
        }

        guard let item = topic[Self.appStoreItemKey],
              case let .bool(reportsTokens)? = item.content[Self.tokenReportingKey] else {
            Logger.debug(Strings.remoteConfig.externalPurchasesPolicyWithoutTokenReporting)
            return false
        }

        return reportsTokens
    }

    private static let appStoreItemKey = "app_store"
    private static let allowedStorefrontsKey = "storefronts_allowed_without_store_eligibility"
    private static let tokenReportingKey = "token_reporting_enabled"

}

extension ExternalPurchasesConfigProvider: @unchecked Sendable {}
