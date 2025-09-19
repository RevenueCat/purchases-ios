//
//  CustomerCenterViewAPI.swift
//  RevenueCatUISwiftAPITester
//
//  Created by Will Taylor on 12/11/24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

#if canImport(UIKit) && os(iOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct TestViewPlusPresentCustomerCenter: View {

    @State private var isPresented = false

    var body: some View {
        EmptyView()
            // Basic presenters
            .presentCustomerCenter(isPresented: $isPresented)
            .presentCustomerCenter(isPresented: $isPresented, onDismiss: {})
            .presentCustomerCenter(
                isPresented: $isPresented,
                customerCenterActionHandler: { (action: CustomerCenterAction) in
                    _ = action
                },
                onDismiss: {}
            )
            // Full presenters with individual handlers
            .presentCustomerCenter(
                isPresented: $isPresented,
                presentationMode: .sheet,
                restoreStarted: {},
                restoreCompleted: { (customerInfo: CustomerInfo) in
                    _ = customerInfo
                },
                restoreFailed: { (error: Error) in
                    _ = error
                },
                showingManageSubscriptions: {},
                refundRequestStarted: { (productId: String) in
                    _ = productId
                },
                refundRequestCompleted: { (productId: String, status: RefundRequestStatus) in
                    _ = productId
                    _ = status
                },
                feedbackSurveyCompleted: { (optionId: String) in
                    _ = optionId
                },
                managementOptionSelected: { (managementOption: CustomerCenterActionable) in
                    _ = managementOption
                },
                onCustomAction: { (actionIdentifier: String, purchaseIdentifier: String?) in
                    _ = actionIdentifier
                    _ = purchaseIdentifier
                },
                changePlansSelected: { (optionId: String) in
                    _ = optionId
                },
                onDismiss: {}
            )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct TestCustomerCenterViewActionsAPI: View {
    var body: some View {
        CustomerCenterView()
            .onCustomerCenterRestoreStarted({})
            .onCustomerCenterRestoreFailed({ (error: Error) in
                _ = error
            })
            .onCustomerCenterRestoreCompleted({ (customerInfo: CustomerInfo) in
                _ = customerInfo
            })
            .onCustomerCenterShowingManageSubscriptions({})
            .onCustomerCenterRefundRequestStarted({ (productId: String) in
                _ = productId
            })
            .onCustomerCenterRefundRequestCompleted({ (productId: String, status: RefundRequestStatus) in
                _ = productId
                _ = status
            })
            .onCustomerCenterFeedbackSurveyCompleted({ (optionId: String) in
                _ = optionId
            })
            .onCustomerCenterManagementOptionSelected({ (managementOption: CustomerCenterActionable) in
                _ = managementOption
            })
            .onCustomerCenterPromotionalOfferSuccess({})
            .onCustomerCenterChangePlansSelected({ (optionId: String) in
                _ = optionId
            })
            .onCustomerCenterCustomActionSelected({ (actionIdentifier: String, purchaseIdentifier: String?) in
                _ = actionIdentifier
                _ = purchaseIdentifier
            })
    }
}
#endif
