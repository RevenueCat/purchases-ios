//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWebPurchaseRedemptionHelper.swift
//
//  Created by Antonio Rico Diez on 6/11/24.

@testable import RevenueCat

class MockWebPurchaseRedemptionHelper: WebPurchaseRedemptionHelperType {

    var invokedHandleRedeemWebPurchase: Bool = false
    var invokedHandleRedeemWebPurchaseCount: Int = 0
    var invokedHandleRedeemWebPurchaseParam: (String)?

    var stubbedHandleRedeemWebPurchaseResult: WebPurchaseRedemptionResult = .invalidToken

    func handleRedeemWebPurchase(redemptionToken: String) async -> WebPurchaseRedemptionResult {
        self.invokedHandleRedeemWebPurchase = true
        self.invokedHandleRedeemWebPurchaseCount += 1
        self.invokedHandleRedeemWebPurchaseParam = redemptionToken

        return stubbedHandleRedeemWebPurchaseResult
    }
}
