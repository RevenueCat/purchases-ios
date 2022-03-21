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

@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(tvOS, unavailable)
class MockSK2BeginRefundRequestHelper: SK2BeginRefundRequestHelper {

    var mockSK2Error: Error?

    // We can't directly store instances of StoreKit.Transaction.RefundRequestStatus, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // So instead, we store the underlying product as Any and wrap it with casting.
    // https://openradar.appspot.com/radar?id=4970535809187840
    private var untypedSK2Status: Any?
    var mockSK2Status: StoreKit.Transaction.RefundRequestStatus? {
        get {
            // swiftlint:disable:next force_cast
            return untypedSK2Status as! StoreKit.Transaction.RefundRequestStatus?
        }
        set {
            untypedSK2Status = newValue
        }
    }

    var transactionVerified = true
    var refundRequestCalled = false
    var verifyTransactionCalled = false

    override func initiateSK2RefundRequest(transactionID: UInt64, windowScene: UIWindowScene) async ->
        Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        refundRequestCalled = true
        if let error = mockSK2Error {
            return .failure(error)
        } else {
            return .success(mockSK2Status ?? StoreKit.Transaction.RefundRequestStatus.success)
        }
    }

    override func verifyTransaction(productID: String) async throws -> UInt64 {
        verifyTransactionCalled = true
        if transactionVerified {
            return UInt64()
        } else {
            let message = "Test error"
            throw ErrorUtils.beginRefundRequestError(withMessage: message)
        }
    }

}
