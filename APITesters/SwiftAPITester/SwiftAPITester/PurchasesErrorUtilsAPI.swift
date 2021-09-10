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
import RevenueCat
import StoreKit

func checkPurchasesErrorUtilsAPI() {
    let underlyingError = NSError(domain: "NetworkErrorDomain", code: 28, userInfo: [String: Any]())
    var error: Error = ErrorUtils.networkError(withUnderlyingError: underlyingError)
    error = ErrorUtils.backendError(withBackendCode: 12345, backendMessage: nil)
    error = ErrorUtils.backendError(withBackendCode: 12345, backendMessage: "message")
    error = ErrorUtils.unexpectedBackendResponseError()
    error = ErrorUtils.missingReceiptFileError()
    error = ErrorUtils.missingAppUserIDError()
    error = ErrorUtils.logOutAnonymousUserError()
    error = ErrorUtils.paymentDeferredError()
    error = ErrorUtils.unknownError()

    let underlyingSKError = NSError(domain: SKErrorDomain, code: SKError.unknown.rawValue, userInfo: nil)
    error = ErrorUtils.purchasesError(withSKError: underlyingSKError)

    print(error, error.localizedDescription)
}
