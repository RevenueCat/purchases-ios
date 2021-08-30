//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesErrorUtilsAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import Purchases
import StoreKit

func checkPurchasesErrorUtilsAPI() {
    let underlyingError = NSError(domain: "NetworkErrorDomain", code: 28, userInfo: [String: Any]())
    var error: Error = Purchases.ErrorUtils.networkError(withUnderlyingError: underlyingError)
    error = Purchases.ErrorUtils.backendError(withBackendCode: 12345, backendMessage: nil)
    error = Purchases.ErrorUtils.backendError(withBackendCode: 12345, backendMessage: "message")
    error = Purchases.ErrorUtils.unexpectedBackendResponseError()
    error = Purchases.ErrorUtils.missingReceiptFileError()
    error = Purchases.ErrorUtils.missingAppUserIDError()
    error = Purchases.ErrorUtils.logOutAnonymousUserError()
    error = Purchases.ErrorUtils.paymentDeferredError()
    error = Purchases.ErrorUtils.unknownError()
    // TODO we had this in objc, do we not in swift?
//    error = Purchases.ErrorUtils.unknownError(message: )

    let underlyingSKError = NSError(domain: SKErrorDomain, code: SKError.unknown.rawValue, userInfo: nil)
    error = Purchases.ErrorUtils.purchasesError(withSKError: underlyingSKError)

    print(error, error.localizedDescription)
}
