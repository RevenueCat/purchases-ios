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
    private let customerInfoManager: CustomerInfoManager

#if os(iOS)
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    lazy var sk2Helper = SK2BeginRefundRequestHelper()
#endif

    init(systemInfo: SystemInfo, customerInfoManager: CustomerInfoManager) {
        self.systemInfo = systemInfo
        self.customerInfoManager = customerInfoManager
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
    func beginRefundRequest(forProduct productID: String,
                            completion: @escaping (Result<RefundRequestStatus, Error>) -> Void) {
        _ = Task<Void, Never> {
            let result = await self.beginRefundRequest(productID: productID)
            completion(result)
        }

        return
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(forEntitlement entitlementID: String,
                            completion: @escaping (Result<RefundRequestStatus, Error>) -> Void) {

        customerInfoManager.customerInfo(appUserID: "1234") { maybeCustomerInfo, maybeError in
            if let error = maybeError {
                let message = "Failed to get CustomerInfo to proceed with refund for entitlement \(entitlementID). Details: \(error.localizedDescription)"
                completion(.failure(ErrorUtils.customerInfoError(withMessage: message, error: error)))
                return
            }

            guard let customerInfo = maybeCustomerInfo else {
                let message = "Failed to get entitlement \(entitlementID) for refund. customerInfo is nil."
                completion(.failure(ErrorUtils.customerInfoError(withMessage: message)))
                return
            }

            guard let entitlement = customerInfo.entitlements[entitlementID] else {
                completion(.failure(ErrorUtils.beginRefundRequestError(withMessage: "Could not find entitlement for refund")))
                return
            }

            _ = Task<Void, Never> {
                let result = await self.beginRefundRequest(productID: entitlement.productIdentifier)
                completion(result)
            }
        }

        return
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequestForActiveEntitlement(completion: @escaping (Result<RefundRequestStatus, Error>) -> Void) {

        customerInfoManager.customerInfo(appUserID: "1234") { maybeCustomerInfo, maybeError in
            if let error = maybeError {
                let message = "Failed to get CustomerInfo to proceed with refund for active entitlement. Details: \(error.localizedDescription)"
                completion(.failure(ErrorUtils.customerInfoError(withMessage: message, error: error)))
                return
            }

            guard let customerInfo = maybeCustomerInfo else {
                let message = "Failed to get active entitlement for refund. customerInfo is nil."
                completion(.failure(ErrorUtils.customerInfoError(withMessage: message)))
                return
            }

            guard let activeEntitlement = customerInfo.entitlements.active.first?.value else {
                completion(.failure(ErrorUtils.beginRefundRequestError(
                    withMessage: "There is no active entitlement to refund")))
                return
            }

            _ = Task<Void, Never> {
                let result = await self.beginRefundRequest(productID: activeEntitlement.productIdentifier)
                completion(result)
            }
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
