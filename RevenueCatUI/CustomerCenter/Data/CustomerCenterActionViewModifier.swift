//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterActionPreferencesViewModifier.swift
//  
//  Created by Cesar de la Vega on 2024-06-17.

import RevenueCat
import SwiftUI

#if os(iOS)

/// A wrapper that makes any value unique by including a UUID
struct UniqueWrapper<T> {
    let id = UUID()
    let value: T
}

extension UniqueWrapper: Equatable {
    static func == (lhs: UniqueWrapper<T>, rhs: UniqueWrapper<T>) -> Bool {
        lhs.id == rhs.id
    }
}

/// A view modifier that connects CustomerCenterViewModel actions to the SwiftUI preference system
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterActionViewModifier: ViewModifier {

    let actionWrapper: CustomerCenterActionWrapper

    @State private var restoreStarted: UniqueWrapper<Void>?
    @State private var restoreFailed: UniqueWrapper<NSError>?
    @State private var restoreCompleted: UniqueWrapper<CustomerInfo>?
    @State private var showingManageSubscriptions: UniqueWrapper<Void>?
    @State private var refundRequestStarted: UniqueWrapper<String>?
    @State private var refundRequestCompleted: UniqueWrapper<(String, RefundRequestStatus)>?
    @State private var feedbackSurveyCompleted: UniqueWrapper<String>?
    @State private var managementOptionSelected: UniqueWrapper<CustomerCenterActionable>?
    @State private var promotionalOfferSuccess: UniqueWrapper<Void>?

    func body(content: Content) -> some View {
        content
            .onAppear {
                setUpActionWrappers()
            }
            // Apply preferences based on state
            .preference(key: CustomerCenterView.RestoreStartedPreferenceKey.self,
                        value: restoreStarted)
            .preference(key: CustomerCenterView.RestoreFailedPreferenceKey.self,
                        value: restoreFailed)
            .preference(key: CustomerCenterView.RestoreCompletedPreferenceKey.self,
                        value: restoreCompleted)
            .preference(key: CustomerCenterView.ShowingManageSubscriptionsPreferenceKey.self,
                        value: showingManageSubscriptions)
            .preference(key: CustomerCenterView.RefundRequestStartedPreferenceKey.self,
                        value: refundRequestStarted)
            .preference(key: CustomerCenterView.RefundRequestCompletedPreferenceKey.self,
                        value: refundRequestCompleted)
            .preference(key: CustomerCenterView.FeedbackSurveyCompletedPreferenceKey.self,
                        value: feedbackSurveyCompleted)
            .preference(key: CustomerCenterView.ManagementOptionSelectedPreferenceKey.self,
                        value: managementOptionSelected)
            .preference(key: CustomerCenterView.PromotionalOfferSuccessPreferenceKey.self,
                        value: promotionalOfferSuccess)
    }

    // Set up direct binding to the state variables
    @MainActor
    private func setUpActionWrappers() {
        actionWrapper.onRestoreStarted {
            restoreStarted = UniqueWrapper(value: ())
        }

        actionWrapper.onRestoreFailed { error in
            restoreFailed = UniqueWrapper(value: error)
        }

        actionWrapper.onRestoreCompleted { info in
            restoreCompleted = UniqueWrapper(value: info)
        }

        actionWrapper.onShowingManageSubscriptions {
            showingManageSubscriptions = UniqueWrapper(value: ())
        }

        actionWrapper.onRefundRequestStarted { productId in
            refundRequestStarted = UniqueWrapper(value: productId)
        }

        actionWrapper.onRefundRequestCompleted { productId, status in
            refundRequestCompleted = UniqueWrapper(value: (productId, status))
        }

        actionWrapper.onFeedbackSurveyCompleted { reason in
            feedbackSurveyCompleted = UniqueWrapper(value: reason)
        }

        actionWrapper.onManagementOptionSelected { action in
            managementOptionSelected = UniqueWrapper(value: action)
        }

        actionWrapper.onPromotionalOfferSuccess {
            promotionalOfferSuccess = UniqueWrapper(value: ())
        }
    }
}

#endif
