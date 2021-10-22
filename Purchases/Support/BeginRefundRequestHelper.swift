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

    @available(iOS 15.0, tvOS 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    lazy var refundRequestHelperSK2 = RefundRequestHelperSK2()

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
        fatalError("Tried to call beginRefundRequest in a platform that doesn't support it!")
#endif
    }

}

#if os(iOS) || targetEnvironment(macCatalyst)
@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension BeginRefundRequestHelper {

    @MainActor
    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(productID: String) async -> Result<RefundRequestStatus, Error> {
        guard let windowScene = systemInfo.sharedUIApplication?.currentWindowScene else {
            return .failure(ErrorUtils.storeProblemError(withMessage: "Failed to get UIWindowScene"))
        }

        let transactionVerificationResult = await refundRequestHelperSK2.verifyTransaction(productID: productID)

        switch transactionVerificationResult {
        case .failure(let verificationError):
            return .failure(verificationError)
        case .success(let transactionID):
            let sk2Result = await refundRequestHelperSK2.initiateRefundRequest(transactionID: transactionID,
                                                                               windowScene: windowScene)
            return sk2Result.map { RefundRequestStatus.from(sk2RefundRequestStatus: $0) }
        }
    }

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
    static func from(sk2RefundRequestStatus status: StoreKit.Transaction.RefundRequestStatus)
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
}
#endif
