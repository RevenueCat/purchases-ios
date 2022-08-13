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
    private let currentUserProvider: CurrentUserProvider

#if os(iOS)

    private var _sk2Helper: Any?

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    var sk2Helper: SK2BeginRefundRequestHelper {
        get {
            // swiftlint:disable:next force_cast
            return self._sk2Helper! as! SK2BeginRefundRequestHelper
        }

        set {
            self._sk2Helper = newValue
        }
    }

#endif

    init(systemInfo: SystemInfo, customerInfoManager: CustomerInfoManager, currentUserProvider: CurrentUserProvider) {
        self.systemInfo = systemInfo
        self.customerInfoManager = customerInfoManager
        self.currentUserProvider = currentUserProvider

        #if os(iOS)
        if #available(iOS 15, *) {
            self._sk2Helper = SK2BeginRefundRequestHelper()
        } else {
            self._sk2Helper = nil
        }
        #endif
    }

#if os(iOS)
    /*
     * Entry point for beginning the refund request. Handles getting the current windowScene and verifying the
     * transaction before calling into `SK2BeginRefundRequestHelper`'s `initiateRefundRequest`.
     */
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @MainActor
    func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus {
        guard let windowScene = systemInfo.sharedUIApplication?.currentWindowScene else {
            throw ErrorUtils.storeProblemError(withMessage: "Failed to get UIWindowScene")
        }

        let transactionID = try await sk2Helper.verifyTransaction(productID: productID)
        return try await sk2Helper.initiateRefundRequest(transactionID: transactionID,
                                                         windowScene: windowScene)
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(forEntitlement entitlementID: String) async throws -> RefundRequestStatus {
        let entitlement = try await getEntitlement(entitlementID: entitlementID)
        return try await self.beginRefundRequest(forProduct: entitlement.productIdentifier)
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequestForActiveEntitlement() async throws -> RefundRequestStatus {
        let activeEntitlement = try await getEntitlement(entitlementID: nil)
        return try await self.beginRefundRequest(forProduct: activeEntitlement.productIdentifier)
    }
#endif
}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
// - It has mutable `_sk2Helper` which is necessary due to the availability annotations.
extension BeginRefundRequestHelper: @unchecked Sendable {}

// MARK: - Private

#if os(iOS)
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension BeginRefundRequestHelper {

    /*
     * Gets entitlement with the given `entitlementID` from customerInfo, or the active entitlement
     * if no ID passed in.
     */
    func getEntitlement(entitlementID: String?) async throws -> EntitlementInfo {
        let customerInfo: CustomerInfo

        do {
            customerInfo = try await self.customerInfoManager.customerInfo(
                appUserID: self.currentUserProvider.currentAppUserID,
                fetchPolicy: .cachedOrFetched
            )
        } catch {
            let message = Strings.purchase.begin_refund_customer_info_error(entitlementID: entitlementID)
                .description
            throw ErrorUtils.beginRefundRequestError(withMessage: message, error: error)
        }

        if let entitlementID = entitlementID {
            guard let entitlement = customerInfo.entitlements[entitlementID] else {
                let message = Strings.purchase
                    .begin_refund_no_entitlement_found(entitlementID: entitlementID)
                    .description
                throw ErrorUtils.beginRefundRequestError(withMessage: message)
            }

            return entitlement
        }

        guard customerInfo.entitlements.active.count < 2 else {
            let message = Strings.purchase.begin_refund_multiple_active_entitlements.description
            throw ErrorUtils.beginRefundRequestError(withMessage: message)
        }

        guard let activeEntitlement = customerInfo.entitlements.active.first?.value else {
            let message = Strings.purchase.begin_refund_no_active_entitlement.description
            throw ErrorUtils.beginRefundRequestError(withMessage: message)
        }

        return activeEntitlement
    }

}
#endif

/// Status codes for refund requests.
@objc(RCRefundRequestStatus) public enum RefundRequestStatus: Int, Sendable {

    /// User canceled submission of the refund request.
    @objc(RCRefundRequestUserCancelled) case userCancelled = 0
    /// Apple has received the refund request.
    @objc(RCRefundRequestSuccess) case success
    /// There was an error with the request. See message for more details.
    @objc(RCRefundRequestError) case error

}
