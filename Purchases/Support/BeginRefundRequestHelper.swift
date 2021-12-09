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
    private let identityManager: IdentityManager

#if os(iOS)
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    lazy var sk2Helper = SK2BeginRefundRequestHelper()
#endif

    init(systemInfo: SystemInfo, customerInfoManager: CustomerInfoManager, identityManager: IdentityManager) {
        self.systemInfo = systemInfo
        self.customerInfoManager = customerInfoManager
        self.identityManager = identityManager
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
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(forEntitlement entitlementID: String,
                            completion: @escaping (Result<RefundRequestStatus, Error>) -> Void) {
        getEntitlement(maybeEntitlementID: entitlementID) { entitlementResult in
            switch entitlementResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let entitlement):
                self.beginRefundRequest(forProduct: entitlement.productIdentifier) { refundResult in
                    completion(refundResult)
                }
            }
        }
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequestForActiveEntitlement(completion: @escaping (Result<RefundRequestStatus, Error>) -> Void) {
        getEntitlement(maybeEntitlementID: nil) { entitlementResult in
            switch entitlementResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let entitlement):
                self.beginRefundRequest(forProduct: entitlement.productIdentifier) { refundResult in
                    completion(refundResult)
                }
            }
        }
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

    /*
     * Gets entitlement with the given `entitlementID` from customerInfo, or the active entitlement
     * if no ID passed in.
     */
    func getEntitlement(maybeEntitlementID: String?,
                        completion: @escaping (Result<EntitlementInfo, Error>) -> Void) {
        let currentAppUserID = identityManager.currentAppUserID
        customerInfoManager.customerInfo(appUserID: currentAppUserID) { maybeCustomerInfo, maybeError in
            if let error = maybeError {
                let message = Strings.purchase.begin_refund_customer_info_error(entitlementID: nil).description
                completion(.failure(ErrorUtils.beginRefundRequestError(withMessage: message, error: error)))
                return
            }

            guard let customerInfo = maybeCustomerInfo else {
                let message = Strings.purchase.begin_refund_for_entitlement_nil_customer_info(
                    entitlementID: nil).description
                completion(.failure(ErrorUtils.beginRefundRequestError(withMessage: message)))
                return
            }

            if let entitlementID = maybeEntitlementID {
                guard let entitlement = customerInfo.entitlements[entitlementID] else {
                    let message = Strings.purchase.begin_refund_no_active_entitlement(
                        entitlementID: entitlementID).description
                    completion(.failure(ErrorUtils.beginRefundRequestError(withMessage: message)))
                    return
                }
                completion(.success(entitlement))
                return
            }

            guard let activeEntitlement = customerInfo.entitlements.active.first?.value else {
                let message = Strings.purchase.begin_refund_no_active_entitlement(entitlementID: nil).description
                completion(.failure(ErrorUtils.beginRefundRequestError(
                    withMessage: message)))
                return
            }

            return completion(.success(activeEntitlement))
        }
        return
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
