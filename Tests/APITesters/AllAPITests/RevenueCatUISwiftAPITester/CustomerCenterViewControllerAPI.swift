//
//  CustomerCenterViewAPI.swift
//  AllAPITests
//
//  Created by Will Taylor on 12/6/24.
//

import RevenueCat
import RevenueCatUI


#if canImport(UIKit) && os(iOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
func checkCustomerCenterViewControllerAPI(
    customerCenterActionHandler: CustomerCenterActionHandler? = nil
) {
    let _ = CustomerCenterViewController()
    let _ = CustomerCenterViewController(customerCenterActionHandler: customerCenterActionHandler)

    let delegate: CustomerCenterViewControllerDelegate? = nil
    let vcWithDelegate = CustomerCenterViewController(delegate: delegate)

    // Full initializer with individual handlers
    let _ = CustomerCenterViewController(
        restoreStarted: {},
        restoreCompleted: { _ in },
        restoreFailed: { _ in },
        showingManageSubscriptions: {},
        refundRequestStarted: { _ in },
        refundRequestCompleted: { _, _ in },
        feedbackSurveyCompleted: { _ in },
        managementOptionSelected: { _ in },
        changePlansSelected: { _ in },
        onCustomAction: { _, _ in },
        promotionalOfferSuccess: {}
    )
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private class MockCustomerCenterViewControllerDelegate: NSObject, CustomerCenterViewControllerDelegate {

    func customerCenterViewControllerDidStartRestore(_ controller: CustomerCenterViewController) {}

    func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didFinishRestoringWith customerInfo: CustomerInfo
    ) {}

    func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didFailRestoringWith error: NSError
    ) {}

    func customerCenterViewControllerDidShowManageSubscriptions(_ controller: CustomerCenterViewController) {}

    func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didStartRefundRequestFor productId: String
    ) {}

    func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didCompleteRefundRequestFor productId: String,
        with status: RefundRequestStatus
    ) {}

    func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didCompleteFeedbackSurveyWith optionId: String
    ) {}

    func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didSelectChangePlansWith optionId: String
    ) {}

    func customerCenterViewController(
        _ controller: CustomerCenterViewController,
        didSelectCustomActionWith actionIdentifier: String,
        purchaseIdentifier: String?
    ) {}

    func customerCenterViewControllerDidSucceedWithPromotionalOffer(_ controller: CustomerCenterViewController) {}

    func customerCenterViewControllerWasDismissed(_ controller: CustomerCenterViewController) {}
}
#endif
