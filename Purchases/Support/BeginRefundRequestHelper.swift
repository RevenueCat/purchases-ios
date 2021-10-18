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

    // TODO figure out whether to have a fallback for unavailable
    // TODO any transactionId checking?
    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(transactionID: UInt64,
                            completion: @escaping (Result<RefundRequestStatus,
                                                   Error>) -> Void) {
        Task {
            self.beginRefundRequest(transactionID: transactionID, completion: completion)
        }
        return
    }

}

@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension BeginRefundRequestHelper {

    @MainActor
    func beginRefundRequest(transactionID: UInt64) async throws
        -> Result<RefundRequestStatus, Error> {
        // TODO pull out to some kind of UIHelper class?
        guard let application = systemInfo.sharedUIApplication,
              let windowScene = application.currentWindowScene else {
                  return .failure(ErrorUtils.storeProblemError(withMessage: "Failed to get UIWindowScene"))
        }

        do {
            let status = try await StoreKit.Transaction.beginRefundRequest(for: transactionID, in: windowScene)
            return .success(RefundRequestStatus.refundRequestStatus(fromSKRefundRequestStatus: status))
        } catch {
            let message = "Error when trying to begin refund request: \(error.localizedDescription)"
            return .failure(ErrorUtils.storeProblemError(withMessage: message, error: error))
        }
    }

}

/// Status codes for refund requests
@objc(RCRefundRequestStatus) public enum RefundRequestStatus: Int {
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

    static func refundRequestStatus(fromSKRefundRequestStatus status: StoreKit.Transaction.RefundRequestStatus)
        -> RefundRequestStatus {
        switch status {
        case .userCancelled:
            return .userCancelled
        case .success:
            return .success
        @unknown default:
            // TODO figure out how to handle this -- .error?
            fatalError()
        }
    }

}
