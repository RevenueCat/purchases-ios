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

class CustomerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType {

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    func renewalInfo(
        for product: RevenueCat.StoreProduct
    ) async -> Product.SubscriptionInfo.RenewalInfo? {
        if #available(macOS 12.0, tvOS 15.0, watchOS 8.0, watchOSApplicationExtension 8.0, *) {
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
        } else {
            return nil
        }
    }
}
