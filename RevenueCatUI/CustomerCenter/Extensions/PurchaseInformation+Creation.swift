//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInformation+Creation.swift
//
//  Created by Facundo Menzella on 21/5/25.

import RevenueCat

extension PurchaseInformation {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    static func from(
        transaction: RevenueCatUI.Transaction,
        customerInfo: CustomerInfo,
        purchasesProvider: CustomerCenterPurchasesType,
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType
    ) async -> PurchaseInformation {
        let entitlement = customerInfo.entitlements.all.values
            .first(where: { $0.productIdentifier == transaction.productIdentifier })

        if transaction.store == .appStore {
            if let product = await purchasesProvider.products([transaction.productIdentifier]).first {
                return await PurchaseInformation.purchaseInformationUsingRenewalInfo(
                    entitlement: entitlement,
                    subscribedProduct: product,
                    transaction: transaction,
                    customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                    customerInfoRequestedDate: customerInfo.requestDate,
                    managementURL: transaction.managementURL
                )
            } else {
                Logger.warning(
                    Strings.could_not_find_product_loading_without_product_information(transaction.productIdentifier)
                )

                return PurchaseInformation(
                    entitlement: entitlement,
                    transaction: transaction,
                    customerInfoRequestedDate: customerInfo.requestDate,
                    managementURL: transaction.managementURL
                )
            }
        }

        Logger.warning(Strings.active_product_is_not_apple_loading_without_product_information(transaction.store))

        return PurchaseInformation(
            entitlement: entitlement,
            transaction: transaction,
            customerInfoRequestedDate: customerInfo.requestDate,
            managementURL: transaction.managementURL
        )
    }
}
