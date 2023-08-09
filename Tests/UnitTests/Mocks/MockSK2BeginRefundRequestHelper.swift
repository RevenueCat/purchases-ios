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

#if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(tvOS, unavailable)
class MockSK2BeginRefundRequestHelper: SK2BeginRefundRequestHelper {

    var mockSK2Error: Error?

    // We can't directly store instances of `StoreKit.Transaction.RefundRequestStatus`, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // https://openradar.appspot.com/radar?id=4970535809187840
    // https://github.com/apple/swift/issues/58099
    private var untypedSK2Status: Box<StoreKit.Transaction.RefundRequestStatus?> = .init(nil)
    var mockSK2Status: StoreKit.Transaction.RefundRequestStatus? {
        get { return self.untypedSK2Status.value }
        set { self.untypedSK2Status = .init(newValue) }
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

#endif
