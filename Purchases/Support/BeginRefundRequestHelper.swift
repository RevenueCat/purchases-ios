//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BeginRefundRequestHelper.swift
//
//  Created by Madeline Beyl on 10/13/21.

import StoreKit

class BeginRefundRequestHelper {

    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(productID: String,
                            completion: @escaping (Result<RefundRequestStatus,
                                                   Error>) -> Void) {
#if os(iOS) || targetEnvironment(macCatalyst)
        Task {
            let result = await self.beginRefundRequest(productID: productID)
            completion(result)
        }

        return
#else
        fatalError("Tried to call Transaction.beginRefundRequest in a platform that doesn't support it!")
#endif
    }
}

private extension BeginRefundRequestHelper {

#if os(iOS) || targetEnvironment(macCatalyst)
    @MainActor
    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(productID: String) async -> Result<RefundRequestStatus, Error> {
        // TODO pull out to some kind of UIHelper class?
        guard let application = systemInfo.sharedUIApplication,
              let windowScene = application.currentWindowScene else {
                  return .failure(ErrorUtils.storeProblemError(withMessage: "Failed to get UIWindowScene"))
        }

        guard let transactionVerificationResult = await StoreKit.Transaction.latest(for: productID) else {
            let message = "Product hasn't been purchased or doesn't exist."
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message))
        }

        switch transactionVerificationResult {
        case .unverified(let transaction, let verificationError):
            let message = "Transaction with ID \(transaction.id) is unverified by AppStore. Verification error " +
                "\(verificationError.localizedDescription)"
            return .failure(ErrorUtils.beginRefundRequestError(withMessage: message))
        case .verified(let transaction):
            do {
                let status = try await StoreKit.Transaction.beginRefundRequest(for: transaction.id, in: windowScene)
                return .success(RefundRequestStatus.refundRequestStatus(fromSKRefundRequestStatus: status))
            } catch {
                let message = getErrorMessage(error: error)
                return .failure(ErrorUtils.beginRefundRequestError(withMessage: message, error: error))
            }
        }
    }
#endif
}

private extension BeginRefundRequestHelper {

#if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func getErrorMessage(error: Error?) -> String {
        if let skError = error as? StoreKit.Transaction.RefundRequestError {
            switch skError {
            case .duplicateRequest:
                return "Refund already requested for this product and is pending, already denied, " +
                    "or already approved."
            case .failed:
                return "Refund request submission failed."
            @unknown default:
                return "Unknown RefundRequestError type."
            }
        } else {
            return "Unexpected error type returned from AppStore: \(String(describing: error?.localizedDescription))"
        }
    }
#endif

}

/// Status codes for refund requests
@objc(RCRefundRequestStatus) public enum RefundRequestStatus: Int {
    // TODO i personally find this confusing, should we make userCancelled an error?
    /// User canceled submission of the refund request
    case userCancelled = 0,
        /// Apple has received the refund request
         success,
         // TODO should this be error or none or what, need to not require nullable enum in status
         error
}

@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension RefundRequestStatus {
#if os(iOS) || targetEnvironment(macCatalyst)
    static func refundRequestStatus(fromSKRefundRequestStatus status: StoreKit.Transaction.RefundRequestStatus)
        -> RefundRequestStatus {
        switch status {
        case .userCancelled:
            return .userCancelled
        case .success:
            return .success
        @unknown default:
            return .error
        }
    }
#endif
}
