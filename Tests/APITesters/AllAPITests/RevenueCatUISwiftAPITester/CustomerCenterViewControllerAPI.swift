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
#endif
