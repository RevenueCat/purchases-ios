//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewControllerDelegate.swift
//
//  Created by Jay Shortway on 29/12/2025.

#if canImport(UIKit) && os(iOS)

import Foundation
import RevenueCat

/// Delegate protocol for ``CustomerCenterViewController``.
///
/// Use this delegate for Objective-C compatibility. Swift users can alternatively use the
/// closure-based initializer.
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@objc(RCCustomerCenterViewControllerDelegate)
public protocol CustomerCenterViewControllerDelegate: NSObjectProtocol {

    /// Called when a restore operation starts.
    @objc(customerCenterViewControllerDidStartRestore:)
    optional func customerCenterViewControllerDidStartRestore(_ controller: CustomerCenterViewController)

    /// Called when a restore operation completes successfully.
    @objc(customerCenterViewController:didFinishRestoringWithCustomerInfo:)
    optional func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    )

    /// Called when a restore operation fails.
    @objc(customerCenterViewController:didFailRestoringWithError:)
    optional func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didFailRestoringWith error: NSError
    )

    /// Called when the user navigates to the manage subscriptions screen.
    @objc(customerCenterViewControllerDidShowManageSubscriptions:)
    optional func customerCenterViewControllerDidShowManageSubscriptions(_ controller: CustomerCenterViewController)

    /// Called when a refund request starts.
    @objc(customerCenterViewController:didStartRefundRequestForProductId:)
    optional func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didStartRefundRequestFor productId: String
    )

    /// Called when a refund request completes.
    @objc(customerCenterViewController:didCompleteRefundRequestForProductId:withStatus:)
    optional func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didCompleteRefundRequestFor productId: String,
        with status: RefundRequestStatus
    )

    /// Called when a feedback survey is completed.
    @objc(customerCenterViewController:didCompleteFeedbackSurveyWithOptionId:)
    optional func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didCompleteFeedbackSurveyWith optionId: String
    )

    /// Called when change plans is selected.
    @objc(customerCenterViewController:didSelectChangePlansWithOptionId:)
    optional func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didSelectChangePlansWith optionId: String
    )

    /// Called when a custom action is selected.
    @objc(customerCenterViewController:didSelectCustomActionWithIdentifier:purchaseIdentifier:)
    optional func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didSelectCustomActionWith actionIdentifier: String,
        purchaseIdentifier: String?
    )

    /// Called when a promotional offer succeeds.
    @objc(customerCenterViewControllerDidSucceedWithPromotionalOffer:)
    optional func customerCenterViewControllerDidSucceedWithPromotionalOffer(_ controller: CustomerCenterViewController)

    /// Called when the Customer Center is dismissed.
    /// Make sure to call dismiss(animated: ) on the CustomerCenterViewController to actually dismiss
    /// the Customer Center.
    @objc(customerCenterViewControllerWasDismissed:)
    optional func customerCenterViewControllerWasDismissed(_ controller: CustomerCenterViewController)
}

#endif
