//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Deprecations.swift
//
//  Created by Nacho Soto on 3/8/22.

import Foundation
import StoreKit

// swiftlint:disable line_length missing_docs

public extension Purchases {

    @available(iOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(tvOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(watchOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macOS, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macCatalyst, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    func checkTrialOrIntroDiscountEligibility(_ productIdentifiers: [String],
                                              completion: @escaping ([String: IntroEligibility]) -> Void) {
        self.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers, completion: completion)
    }

    @available(iOS, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(tvOS, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(watchOS, introduced: 6.2, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macOS, introduced: 10.15, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    @available(macCatalyst, introduced: 13.0, deprecated: 1, renamed: "checkTrialOrIntroDiscountEligibility(productIdentifiers:)")
    func checkTrialOrIntroDiscountEligibility(_ productIdentifiers: [String]) async -> [String: IntroEligibility] {
        return await self.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIdentifiers)
    }

    @available(iOS, introduced: 13.0, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(tvOS, introduced: 13.0, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(watchOS, introduced: 6.2, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(macOS, introduced: 10.15, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    @available(macCatalyst, introduced: 13.0, deprecated, renamed: "promotionalOffer(forProductDiscount:product:)")
    func getPromotionalOffer(forProductDiscount discount: StoreProductDiscount,
                             product: StoreProduct) async throws -> PromotionalOffer {
        return try await self.promotionalOffer(forProductDiscount: discount, product: product)
    }

    @available(iOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(tvOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(watchOS, introduced: 6.2, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(macOS, introduced: 10.15, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    @available(macCatalyst, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers(forProduct:)")
    func getEligiblePromotionalOffers(forProduct product: StoreProduct) async -> [PromotionalOffer] {
        return await eligiblePromotionalOffers(forProduct: product)
    }

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
    @objc(configureWithAPIKey:appUserID:)
    @discardableResult static func configure(withAPIKey apiKey: String, appUserID: String?) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: false)
    }

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
    @objc(configureWithAPIKey:appUserID:observerMode:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool) -> Purchases {
        configure(withAPIKey: apiKey, appUserID: appUserID, observerMode: observerMode, userDefaults: nil)
    }

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?) -> Purchases {
        configure(
            withAPIKey: apiKey,
            appUserID: appUserID,
            observerMode: observerMode,
            userDefaults: userDefaults,
            useStoreKit2IfAvailable: false
        )
    }

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:useStoreKit2IfAvailable:)
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?,
                                             useStoreKit2IfAvailable: Bool) -> Purchases {
        configure(
            withAPIKey: apiKey,
            appUserID: appUserID,
            observerMode: observerMode,
            userDefaults: userDefaults,
            useStoreKit2IfAvailable: useStoreKit2IfAvailable,
            dangerousSettings: nil
        )
    }

    @available(iOS, deprecated: 1, renamed: "configure(with:)")
    @available(tvOS, deprecated: 1, renamed: "configure(with:)")
    @available(watchOS, deprecated: 1, renamed: "configure(with:)")
    @available(macOS, deprecated: 1, renamed: "configure(with:)")
    @available(macCatalyst, deprecated: 1, renamed: "configure(with:)")
    @objc(configureWithAPIKey:appUserID:observerMode:userDefaults:useStoreKit2IfAvailable:dangerousSettings:)
    // swiftlint:disable:next function_parameter_count
    @discardableResult static func configure(withAPIKey apiKey: String,
                                             appUserID: String?,
                                             observerMode: Bool,
                                             userDefaults: UserDefaults?,
                                             useStoreKit2IfAvailable: Bool,
                                             dangerousSettings: DangerousSettings?) -> Purchases {
        return Self.configure(
            withAPIKey: apiKey,
            appUserID: appUserID,
            observerMode: observerMode,
            userDefaults: userDefaults,
            storeKit2Setting: .init(useStoreKit2IfAvailable: useStoreKit2IfAvailable),
            storeKitTimeout: Configuration.storeKitRequestTimeoutDefault,
            networkTimeout: Configuration.networkTimeoutDefault,
            dangerousSettings: dangerousSettings
        )
    }

}

public extension StoreProduct {

    @available(iOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(tvOS, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(watchOS, introduced: 6.2, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(macOS, introduced: 10.15, deprecated, renamed: "eligiblePromotionalOffers()")
    @available(macCatalyst, introduced: 13.0, deprecated, renamed: "eligiblePromotionalOffers()")
    func getEligiblePromotionalOffers() async -> [PromotionalOffer] {
        return await self.eligiblePromotionalOffers()
    }

}

extension CustomerInfo {

    /// Returns all product IDs of the non-subscription purchases a user has made.
    @available(*, deprecated, message: "use nonSubscriptionTransactions")
    @objc public var nonConsumablePurchases: Set<String> {
        return Set(self.nonSubscriptionTransactions.map { $0.productIdentifier })
    }

}
