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

#if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
import Foundation
import StoreKit
import UIKit

@available(iOS 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
protocol SK2BeginRefundRequestHelperType: Sendable {

    func initiateSK2RefundRequest(transactionID: UInt64, windowScene: UIWindowScene) async ->
        Result<StoreKit.Transaction.RefundRequestStatus, Error>

    func verifyTransaction(productID: String) async throws -> UInt64

}

/// Helper class responsible for calling into StoreKit2 and translating results/errors for consumption by RevenueCat.
@available(iOS 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
final class SK2BeginRefundRequestHelper: SK2BeginRefundRequestHelperType {

    /* Checks with StoreKit2 that the given `productID` has an existing verified transaction, and maps the
     * result for consumption by `BeginRefundRequestHelper`.
     */
    func verifyTransaction(productID: String) async throws -> UInt64 {
        let result = await StoreKit.Transaction.latest(for: productID)
        guard let nonNilResult = result else {
            let errorMessage = Strings.purchase.product_unpurchased_or_missing.description
            Logger.error(errorMessage)
            throw ErrorUtils.beginRefundRequestError(withMessage: errorMessage)
        }

        switch nonNilResult {
        case .unverified(_, let verificationError):
            let message = Strings.purchase.transaction_unverified(
                productID: productID,
                errorMessage: verificationError.localizedDescription).description
            Logger.error(message)
            throw ErrorUtils.beginRefundRequestError(withMessage: message)
        case .verified(let transaction): return transaction.id
        }
    }

    /*
     * Attempts to begin a refund request for the given transactionID and current windowScene with StoreKit2.
     * If successful, passes result on as-is. If unsuccessful, calls `getErrorMessage` to add more
     * descriptive details to the error.
     *
     * This function allows for us to mock the StoreKit2 response in unit tests.
     */
    @MainActor
    func initiateSK2RefundRequest(transactionID: UInt64, windowScene: UIWindowScene) async ->
    Result<StoreKit.Transaction.RefundRequestStatus, Error> {
        do {
            let sk2Status = try await StoreKit.Transaction.beginRefundRequest(for: transactionID, in: windowScene)
            return .success(sk2Status)
        } catch {
            let message = getErrorMessage(from: error)
            Logger.error(message)
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message, error: error))
        }
    }

}

@available(iOS 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
extension SK2BeginRefundRequestHelperType {

    /// Calls `initiateSK2RefundRequest` and maps the result for consumption by `BeginRefundRequestHelper`
    @MainActor
    func initiateRefundRequest(transactionID: UInt64, windowScene: UIWindowScene) async throws -> RefundRequestStatus {
        let sk2Result = await self.initiateSK2RefundRequest(transactionID: transactionID, windowScene: windowScene)
        return try self.mapSk2Result(from: sk2Result)
    }

}

@available(iOS 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension SK2BeginRefundRequestHelperType {

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
    func mapSk2Result(from sk2Result: Result<StoreKit.Transaction.RefundRequestStatus, Error>) throws ->
        RCRefundRequestStatus {
        switch sk2Result {
        case .success(let sk2Status):
            guard let rcStatus = RefundRequestStatus.from(sk2RefundRequestStatus: sk2Status) else {
                let message = Strings.purchase.unknown_refund_request_status.description
                Logger.error(message)
                throw ErrorUtils.beginRefundRequestError(
                    withMessage: message)
            }
            return rcStatus
        case .failure(let error):
            Logger.error(error.localizedDescription)
            throw error
        }
    }

}

@available(iOS 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension RefundRequestStatus {

    static func from(sk2RefundRequestStatus status: StoreKit.Transaction.RefundRequestStatus) -> RefundRequestStatus? {
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
