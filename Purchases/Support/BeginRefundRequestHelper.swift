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

import Foundation

/**
 * Helper class responsible for handling any non-store-specific code involved in beginning a refund request.
 * Delegates store-specific operations to `SK2BeginRefundRequestHelper`.
 */
class BeginRefundRequestHelper {

    private let systemInfo: SystemInfo

#if os(iOS)
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    lazy var sk2Helper = SK2BeginRefundRequestHelper()
#endif

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

#if os(iOS)
    /*
     * Entry point for beginning the refund request. fatalErrors if beginning a refund request is not supported
     * on the current platform, else passes the request on to `beginRefundRequest(productID:)`.
     */
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(productID: String, completion: @escaping (Result<RefundRequestStatus, Error>) -> Void) {
        _ = Task<Void, Never> {
            let result = await self.beginRefundRequest(productID: productID)
            completion(result)
        }

        return
    }
#endif
}

#if os(iOS)
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension BeginRefundRequestHelper {

    /*
     * Main worker function for beginning a refund request. Handles getting the current windowScene and verifying the
     * transaction before calling into `SK2BeginRefundRequestHelper`'s `initiateRefundRequest`.
     */
    @MainActor
    func beginRefundRequest(productID: String) async -> Result<RefundRequestStatus, Error> {
        guard let windowScene = systemInfo.sharedUIApplication?.currentWindowScene else {
            return .failure(ErrorUtils.storeProblemError(withMessage: "Failed to get UIWindowScene"))
        }

        let transactionVerificationResult = await sk2Helper.verifyTransaction(productID: productID)

        switch transactionVerificationResult {
        case .failure(let verificationError):
            return .failure(verificationError)
        case .success(let transactionID):
            return await sk2Helper.initiateRefundRequest(transactionID: transactionID,
                                                         windowScene: windowScene)
        }
    }

}
#endif

/// Status codes for refund requests.
@objc(RCRefundRequestStatus) public enum RefundRequestStatus: Int {

    /// User canceled submission of the refund request.
    @objc(RCRefundRequestUserCancelled) case userCancelled = 0
    /// Apple has received the refund request.
    @objc(RCRefundRequestSuccess) case success
    /// There was an error with the request. See message for more details.
    @objc(RCRefundRequestError) case error

}
