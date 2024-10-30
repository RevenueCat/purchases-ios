//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebPurchaseRedemptionResultAPI.swift
//
//  Created by Toni Rico on 10/30/24.

import Foundation
import RevenueCat

var result: WebPurchaseRedemptionResult!
func checkWebPurchaseRedemptionResultEnums() {
    switch result! {
    case let .success(customerInfo):
        let custInfo: CustomerInfo = customerInfo
        print(custInfo)
    case let .error(error):
        let publicError: PublicError = error
        print(publicError)
    @unknown default: fatalError()
    }
}
