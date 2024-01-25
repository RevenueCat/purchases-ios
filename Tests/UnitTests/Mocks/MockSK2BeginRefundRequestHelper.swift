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
final class MockSK2BeginRefundRequestHelper: SK2BeginRefundRequestHelperType {

    private let _mockSK2Error: Atomic<Error?> = .init(nil)
    private let _sk2Status: Atomic<StoreKit.Transaction.RefundRequestStatus?> = .init(nil)
    private let _transactionVerified: Atomic<Bool> = true
    private let _refundRequestCalled: Atomic<Bool> = false
    private let _verifyTransactionCalled: Atomic<Bool> = false

    var mockSK2Error: Error? {
        get { self._mockSK2Error.value }
        set { self._mockSK2Error.value = newValue }
    }

    var mockSK2Status: StoreKit.Transaction.RefundRequestStatus? {
        get { return self._sk2Status.value }
        set { self._sk2Status.value = newValue }
    }

    var refundRequestCalled: Bool {
        get { return self._refundRequestCalled.value }
        set { self._refundRequestCalled.value = newValue }
    }
    var transactionVerified: Bool {
        get { return self._transactionVerified.value }
        set { self._transactionVerified.value = newValue }
    }
    var verifyTransactionCalled: Bool {
        get { return self._verifyTransactionCalled.value }
        set { self._verifyTransactionCalled.value = newValue }
    }

    func initiateSK2RefundRequest(
        transactionID: UInt64, windowScene: UIWindowScene
    ) async -> Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        self.refundRequestCalled = true

        if let error = self.mockSK2Error {
            return .failure(error)
        } else {
            return .success(self.mockSK2Status ?? .success)
        }
    }

    func verifyTransaction(productID: String) async throws -> UInt64 {
        self.verifyTransactionCalled = true

        if self.transactionVerified {
            return 0
        } else {
            throw ErrorUtils.beginRefundRequestError(withMessage: "Test error")
        }
    }

}

#endif
