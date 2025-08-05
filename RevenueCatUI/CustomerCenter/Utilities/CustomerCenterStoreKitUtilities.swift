//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterStoreKitUtilities.swift
//
//  Created by Will Taylor on 12/18/24.

import Foundation
import StoreKit

import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
final class CustomerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType {

    func renewalPriceFromRenewalInfo(for product: StoreProduct) async -> (price: Decimal, currencyCode: String)? {

        #if compiler(>=6.0)
        guard let renewalInfo = await renewalInfo(for: product) else { return nil }
        guard let renewalPrice = renewalInfo.renewalPrice else { return nil }
        guard let currencyCode = currencyCode(fromRenewalInfo: renewalInfo) else { return nil }

        return (renewalPrice, currencyCode)
        #else
        return nil
        #endif
    }

    private func currencyCode(
        fromRenewalInfo renewalInfo: Product.SubscriptionInfo.RenewalInfo,
        locale: Locale = Locale.current
    ) -> String? {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, watchOSApplicationExtension 9.0, *) {

            // renewalInfo.currency was introduced in iOS 18.0 and backdeployed through iOS 16.0
            // However, Xcode versions <15.0 don't have the symbols, so we need to check the compiler version
            // to make sure that this is being built with an Xcode version >=15.0.
            #if compiler(>=6.0)
            guard let currency = renewalInfo.currency else { return nil }
            if currency.isISOCurrency {
                return currency.identifier
            } else {
                return nil
            }
            #else
            return nil
            #endif
        } else {
            #if os(visionOS) || compiler(<6.0)
            return nil
            #else
            return renewalInfo.currencyCode
            #endif
        }
    }

    private func renewalInfo(
        for product: RevenueCat.StoreProduct
    ) async -> Product.SubscriptionInfo.RenewalInfo? {
        guard let statuses = try? await product.sk2Product?.subscription?.status, !statuses.isEmpty else {
            // If StoreKit.Product.subscription is nil, then the product isn't a subscription
            // If statuses is empty, the subscriber was never subscribed to a product in the subscription group.
            return nil
        }

        guard let purchaseSubscriptionStatus = statuses.first(where: {
            do {
                return try $0.transaction.payloadValue.ownershipType == .purchased
            } catch {
                return false
            }
        }) else {
            return nil
        }

        switch purchaseSubscriptionStatus.renewalInfo {
        case .unverified:
            return nil
        case .verified(let renewalInfo):
            return renewalInfo
        }
    }
}
