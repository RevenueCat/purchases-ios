//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockRefundRequestHelperSK2.swift
//
//  Created by Madeline Beyl on 10/21/21.

import Foundation
@testable import RevenueCat
import StoreKit

@available(iOS 15.0, tvOS 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
class MockRefundRequestHelperSK2: RefundRequestHelperSK2 {

    var mockError: Error?
    var mockStatus: StoreKit.Transaction.RefundRequestStatus?
    var transactionVerified = true

    var refundRequestCalled = false
    var verifyTransactionCalled = false

    override func initiateRefundRequest(transactionID: UInt64, windowScene: UIWindowScene) async ->
        Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        refundRequestCalled = true
        if let error = mockError {
            return .failure(error)
        } else {
            return .success(mockStatus ?? StoreKit.Transaction.RefundRequestStatus.success)
        }
    }

    override func verifyTransaction(productID: String) async -> Result<UInt64, Error> {
        verifyTransactionCalled = true
        if transactionVerified {
            return .success(UInt64())
        } else {
            let message = "Test error"
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message))
        }
    }
}
