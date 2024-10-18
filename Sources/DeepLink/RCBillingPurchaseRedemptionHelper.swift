//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCBillingPurchaseRedemptionHelper.swift
//
//  Created by Antonio Rico Diez on 2024-10-17.

import Foundation

class RCBillingPurchaseRedemptionHelper {

    private let backend: Backend
    private let identityManager: IdentityManager

    init(backend: Backend,
         identityManager: IdentityManager) {
        self.backend = backend
        self.identityManager = identityManager
    }

    func handleRedeemRCBPurchase(redemptionToken: String) {
        print("Redeeming RCBilling purchase.")
        self.backend.redeemRCBillingPurchaseAPI.postRedeemRCBillingPurchase(appUserID: identityManager.currentAppUserID,
                                                                            redemptionToken: redemptionToken) { result in
            switch result {
            case let .success(customerInfo):
                print("Redeemed RCBilling purchase. CustomerInfo: \(customerInfo)")
            case let .failure(error):
                print("Failed redeeming purchase. Error: \(error)")
            }
        }
    }
}
