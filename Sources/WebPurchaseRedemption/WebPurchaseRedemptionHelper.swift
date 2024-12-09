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

protocol WebPurchaseRedemptionHelperType {

    func handleRedeemWebPurchase(redemptionToken: String) async -> WebPurchaseRedemptionResult

}

actor WebPurchaseRedemptionHelper: WebPurchaseRedemptionHelperType {

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

    func handleRedeemWebPurchase(redemptionToken: String) async -> WebPurchaseRedemptionResult {
        Logger.verbose(Strings.webRedemption.redeeming_web_purchase)
        return await withCheckedContinuation { continuation in
            self.backend.redeemWebPurchaseAPI.postRedeemWebPurchase(appUserID: identityManager.currentAppUserID,
                                                                    redemptionToken: redemptionToken) { result in
                switch result {
                case let .success(customerInfo):
                    Logger.debug(Strings.webRedemption.redeemed_web_purchase)
                    self.customerInfoManager.cache(customerInfo: customerInfo,
                                                   appUserID: self.identityManager.currentAppUserID)
                    continuation.resume(returning: .success(customerInfo))
                case let .failure(error):
                    Logger.error(Strings.webRedemption.error_redeeming_web_purchase(error))
                    let purchasesError = error.asPurchasesError
                    switch purchasesError.errorCode {
                    case ErrorCode.invalidWebPurchaseToken.rawValue:
                        continuation.resume(returning: .invalidToken)
                    case ErrorCode.purchaseBelongsToOtherUser.rawValue:
                        continuation.resume(returning: .purchaseBelongsToOtherUser)
                    case ErrorCode.expiredWebPurchaseToken.rawValue:
                        guard let obfuscatedEmail = purchasesError.userInfo[ErrorDetails.obfuscatedEmailKey] as? String
                        else {
                            continuation.resume(returning: .error(error.asPublicError))
                            return
                        }
                        continuation.resume(returning: .expired(obfuscatedEmail))
                    default:
                        continuation.resume(returning: .error(error.asPublicError))
                    }
                }
            }
        }
    }
}
