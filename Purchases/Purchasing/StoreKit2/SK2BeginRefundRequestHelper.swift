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

#if os(iOS) || targetEnvironment(macCatalyst)
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
    Result<RevenueCat.RefundRequestStatus, Error> {
        let sk2Result = await initiateSK2RefundRequest(transactionID: transactionID, windowScene: windowScene)
        return mapSk2Result(from: sk2Result)
    }

    func verifyTransaction(productID: String) async -> Result<UInt64, Error> {
        let maybeResult: VerificationResult<StoreKit.Transaction>? = await StoreKit.Transaction.latest(for: productID)
        guard let nonNilResult = maybeResult else {
            return .failure(ErrorUtils.beginRefundRequestError(
                withMessage: Strings.purchase.product_unpurchased_or_missing.description))
        }

        switch nonNilResult {
        case .unverified(_, let verificationError):
            let message = Strings.purchase.transaction_unverified(
                productID: productID,
                errorMessage: verificationError.localizedDescription).description
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message))
        case .verified(let transaction): return .success(transaction.id)
        }
    }

    @MainActor
    func initiateSK2RefundRequest(transactionID: UInt64, windowScene: UIWindowScene) async ->
    Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        do {
            let sk2Status = try await StoreKit.Transaction.beginRefundRequest(for: transactionID, in: windowScene)
            return .success(sk2Status)
        } catch {
            let message = getErrorMessage(from: error)
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message, error: error))
        }
    }

}

@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
private extension SK2BeginRefundRequestHelper {

    func getErrorMessage(from sk2Error: Error?) -> String {
        let details = sk2Error?.localizedDescription ?? "No extra info"
        if let skError = sk2Error as? StoreKit.Transaction.RefundRequestError {
            switch skError {
            case .duplicateRequest:
                return Strings.purchase.duplicate_refund_request(details: details).description
            case .failed:
                return Strings.purchase.failed_refund_request(details: details).description
            @unknown default:
                return Strings.purchase.unknown_refund_request_error_type(details: details).description
            }
        } else {
            return Strings.purchase.unknown_refund_request_error(details: details).description
        }
    }

    /*
     * - Parameter sk2Result: The Result returned from StoreKit2
     * - Returns The result expected by `BeginRefundRequestHelper`, converting from a StoreKit RefundRequestStatus
     * to our `RefundRequestStatus` type and adding more descriptive error messages where needed.
     */
    func mapSk2Result(from sk2Result: Result<StoreKit.Transaction.RefundRequestStatus, Error>) ->
        Result<RevenueCat.RefundRequestStatus, Error> {
        switch sk2Result {
        case .success(let sk2Status):
            guard let rcStatus = RefundRequestStatus.from(sk2RefundRequestStatus: sk2Status) else {
                return .failure(ErrorUtils.beginRefundRequestError(
                    withMessage: Strings.purchase.unknown_refund_request_status.description))
            }
            return .success(rcStatus)
        case .failure(let error):
            let message = getErrorMessage(from: error)
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message))
        }
    }

}

@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
private extension RefundRequestStatus {
    static func from(sk2RefundRequestStatus status: StoreKit.Transaction.RefundRequestStatus)
        -> RefundRequestStatus? {
        switch status {
        case .userCancelled:
            return .userCancelled
        case .success:
            return .success
        @unknown default:
            return nil
        }
    }
}
#endif
