//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2BeginRefundRequestHelper.swift
//
//  Created by Madeline Beyl on 10/21/21.

import Foundation
import StoreKit
import UIKit

@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
class SK2BeginRefundRequestHelper {

    @MainActor
    func initiateRefundRequest(transactionID: UInt64, windowScene: UIWindowScene) async ->
        Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        do {
            let status = try await StoreKit.Transaction.beginRefundRequest(for: transactionID, in: windowScene)
            return .success(status)
        } catch {
            let message = getErrorMessage(error: error)
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message, error: error))
        }
    }

    func verifyTransaction(productID: String) async -> Result<UInt64, Error> {
        let maybeResult: VerificationResult<StoreKit.Transaction>? = await StoreKit.Transaction.latest(for: productID)
        guard let nonNilResult = maybeResult else {
            let message = "Product hasn't been purchased or doesn't exist."
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message))
        }

        switch nonNilResult {
        case .unverified(_, let verificationError):
            let message = "Transaction for productID \(productID) is unverified by AppStore. Verification error " +
                "\(verificationError.localizedDescription)"
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message))
        case .verified(let transaction): return .success(transaction.id)
        }
    }

    func getErrorMessage(error: Error?) -> String {
        let description = error?.localizedDescription ?? "No extra info"
        if let skError = error as? StoreKit.Transaction.RefundRequestError {
            switch skError {
            case .duplicateRequest:
                return "Refund already requested for this product and is either pending, already denied, " +
                    "or already approved: \(description)"
            case .failed:
                return "Refund request submission failed: \(description)"
            @unknown default:
                return "Unknown RefundRequestError type from the AppStore: \(description)"
            }
        } else {
            return "Unexpected error type returned from AppStore: \(description)"
        }
    }

}
