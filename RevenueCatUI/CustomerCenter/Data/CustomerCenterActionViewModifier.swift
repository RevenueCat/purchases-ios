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

    @Environment(\.customerCenterActions) private var actions: CustomerCenterEnvironmentActions
    @State private var cancellables: Set<AnyCancellable> = []

    func body(content: Content) -> some View {
        content
            .onAppear {
                subscribeToActionWrapper()
            }
    }

    @MainActor
    private func subscribeToActionWrapper() {
        subscribeToRestoreActions()
        subscribeToRefundActions()
        subscribeToOtherActions()
    }

    @MainActor
    private func subscribeToRestoreActions() {
        actionWrapper.onCustomerCenterRestoreStarted {
            actions.restoreStarted()
        }
        .store(in: &cancellables)

        actionWrapper.onCustomerCenterRestoreFailed { error in
            actions.restoreFailed(error)
        }
        .store(in: &cancellables)

        actionWrapper.onCustomerCenterRestoreCompleted { info in
            actions.restoreCompleted(info)
        }
        .store(in: &cancellables)
    }

    @MainActor
    private func subscribeToRefundActions() {
        actionWrapper.onCustomerCenterShowingManageSubscriptions {
            actions.showingManageSubscriptions()
        }.store(in: &cancellables)

        actionWrapper.onCustomerCenterRefundRequestStarted { productId in
            actions.refundRequestStarted(productId)
        }.store(in: &cancellables)

        actionWrapper.onCustomerCenterRefundRequestCompleted { productId, status in
            actions.refundRequestCompleted(productId, status)
        }.store(in: &cancellables)
    }

    @MainActor
    private func subscribeToOtherActions() {
        actionWrapper.onCustomerCenterFeedbackSurveyCompleted { reason in
            actions.feedbackSurveyCompleted(reason)
        }
        .store(in: &cancellables)

        actionWrapper.onCustomerCenterManagementOptionSelected { action in
            actions.managementOptionSelected(action)
        }
        .store(in: &cancellables)

        actionWrapper.onCustomerCenterPromotionalOfferSuccess {
            actions.promotionalOfferSuccess()
        }
        .store(in: &cancellables)

        actionWrapper.onCustomerCenterChangePlansSelected { subscriptionGroupID in
            if let id = subscriptionGroupID {
                actions.changePlansSelected(id)
            }
        }
        .store(in: &cancellables)

        actionWrapper.onCustomerCenterCustomActionSelected { actionIdentifier, activePurchaseId in
            actions.customActionSelected(actionIdentifier, activePurchaseId)
        }.store(in: &cancellables)
    }
}

#endif
