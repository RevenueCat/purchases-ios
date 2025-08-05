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

import Combine
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

/// A view modifier that connects CustomerCenterViewModel actions to the SwiftUI preference system using Combine
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
    @State private var showingChangePlans: UniqueWrapper<String?>?
    @State private var managementOptionSelected: UniqueWrapper<CustomerCenterActionable>?
    @State private var customActionSelected: UniqueWrapper<(String, String?)>?
    @State private var promotionalOfferSuccess: UniqueWrapper<Void>?

    @State private var cancellables = Set<AnyCancellable>()

    func body(content: Content) -> some View {
        content
            .onAppear {
                subscribeToActionWrapper()
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
            .preference(key: CustomerCenterView.CustomActionPreferenceKey.self,
                        value: customActionSelected)
            .preference(key: CustomerCenterView.PromotionalOfferSuccessPreferenceKey.self,
                        value: promotionalOfferSuccess)
            .preference(key: CustomerCenterView.ChangePlansSelectedPreferenceKey.self,
                        value: showingChangePlans)
    }

    @MainActor
    private func subscribeToActionWrapper() {
        subscribeToRestoreActions()
        subscribeToRefundActions()
        subscribeToOtherActions()
    }

    @MainActor
    private func subscribeToRestoreActions() {
        actionWrapper.restoreStarted
            .sink { _ in
                restoreStarted = UniqueWrapper(value: ())
            }
            .store(in: &cancellables)

        actionWrapper.restoreFailed
            .sink { error in
                restoreFailed = UniqueWrapper(value: error)
            }
            .store(in: &cancellables)

        actionWrapper.restoreCompleted
            .sink { info in
                restoreCompleted = UniqueWrapper(value: info)
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func subscribeToRefundActions() {
        actionWrapper.showingManageSubscriptions
            .sink { _ in
                showingManageSubscriptions = UniqueWrapper(value: ())
            }
            .store(in: &cancellables)

        actionWrapper.refundRequestStarted
            .sink { productId in
                refundRequestStarted = UniqueWrapper(value: productId)
            }
            .store(in: &cancellables)

        actionWrapper.refundRequestCompleted
            .sink { productId, status in
                refundRequestCompleted = UniqueWrapper(value: (productId, status))
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func subscribeToOtherActions() {
        actionWrapper.feedbackSurveyCompleted
            .sink { reason in
                feedbackSurveyCompleted = UniqueWrapper(value: reason)
            }
            .store(in: &cancellables)

        actionWrapper.managementOptionSelected
            .sink { action in
                managementOptionSelected = UniqueWrapper(value: action)
            }
            .store(in: &cancellables)

        actionWrapper.promotionalOfferSuccess
            .sink { _ in
                promotionalOfferSuccess = UniqueWrapper(value: ())
            }
            .store(in: &cancellables)

        actionWrapper.showingChangePlans
            .sink { subscriptionGroupID in
                showingChangePlans = UniqueWrapper(value: subscriptionGroupID)
            }
            .store(in: &cancellables)

        actionWrapper.customActionSelected
            .sink { actionIdentifier, activePurchaseId in
                customActionSelected = UniqueWrapper(value: (actionIdentifier, activePurchaseId))
            }
            .store(in: &cancellables)
    }
}

#endif
