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
                customerCenterActionHandler: { _ in },
                onDismiss: {}
            )
            // Full presenters with individual handlers
            .presentCustomerCenter(
                isPresented: $isPresented,
                presentationMode: .sheet,
                restoreStarted: {},
                restoreCompleted: { _ in },
                restoreFailed: { _ in },
                showingManageSubscriptions: {},
                refundRequestStarted: { _ in },
                refundRequestCompleted: { _, _ in },
                feedbackSurveyCompleted: { _ in },
                managementOptionSelected: { _ in },
                onCustomAction: { _, _ in },
                changePlansSelected: { _ in },
                onDismiss: {}
            )
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct TestCustomerCenterViewActionsAPI: View {
    var body: some View {
        CustomerCenterView()
            .onCustomerCenterRestoreStarted({})
            .onCustomerCenterRestoreFailed({ _ in })
            .onCustomerCenterRestoreCompleted({ _ in })
            .onCustomerCenterShowingManageSubscriptions({})
            .onCustomerCenterRefundRequestStarted({ _ in })
            .onCustomerCenterRefundRequestCompleted({ _, _ in })
            .onCustomerCenterFeedbackSurveyCompleted({ _ in })
            .onCustomerCenterManagementOptionSelected({ _ in })
            .onCustomerCenterPromotionalOfferSuccess({})
            .onCustomerCenterChangePlansSelected({ _ in })
            .onCustomerCenterCustomActionSelected({ _, _ in })
    }
}
#endif
