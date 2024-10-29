//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebPurchaseRedemptionHelper.swift
//
//  Created by Antonio Rico Diez on 2024-10-17.

import Foundation

class WebPurchaseRedemptionHelper {

    private let backend: Backend
    private let identityManager: IdentityManager
    private let customerInfoManager: CustomerInfoManager

    init(backend: Backend,
         identityManager: IdentityManager,
         customerInfoManager: CustomerInfoManager) {
        self.backend = backend
        self.identityManager = identityManager
        self.customerInfoManager = customerInfoManager
    }

    func handleRedeemWebPurchase(redemptionToken: String,
                                 completion: @escaping (@Sendable (WebPurchaseRedemptionResult) -> Void)) {
        Logger.verbose(Strings.webRedemption.redeeming_web_purchase)
        self.backend.redeemWebPurchaseAPI.postRedeemWebPurchase(appUserID: identityManager.currentAppUserID,
                                                                redemptionToken: redemptionToken) { result in
            switch result {
            case let .success(customerInfo):
                Logger.debug(Strings.webRedemption.redeemed_web_purchase)
                self.customerInfoManager.cache(customerInfo: customerInfo,
                                               appUserID: self.identityManager.currentAppUserID)
                completion(WebPurchaseRedemptionResult.Success(customerInfo: customerInfo))
            case let .failure(error):
                Logger.error(Strings.webRedemption.error_redeeming_web_purchase(error))
                completion(WebPurchaseRedemptionResult.Error(error: error.asPublicError))
            }
        }
    }
}
