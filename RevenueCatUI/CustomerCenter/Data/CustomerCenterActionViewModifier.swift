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

/// A view modifier that subscribes to internal Customer Center actions and forwards them to environment-provided
/// callbacks.
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterActionViewModifier: ViewModifier {

    let actionWrapper: CustomerCenterActionWrapper

    @Environment(\.customerCenterExternalActions) private var actions: CustomerCenterExternalActions
    @State private var cancellables = Set<AnyCancellable>()

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
        actionWrapper.restoreStartedPublisher
            .sink { actions.restoreStarted() }
            .store(in: &cancellables)

        actionWrapper.restoreFailedPublisher
            .sink { actions.restoreFailed($0) }
            .store(in: &cancellables)

        actionWrapper.restoreCompletedPublisher
            .sink { actions.restoreCompleted($0) }
            .store(in: &cancellables)
    }

    @MainActor
    private func subscribeToRefundActions() {
        actionWrapper.showingManageSubscriptionsPublisher
            .sink { actions.showingManageSubscriptions() }
            .store(in: &cancellables)

        actionWrapper.refundRequestStartedPublisher
            .sink { actions.refundRequestStarted($0) }
            .store(in: &cancellables)

        actionWrapper.refundRequestCompletedPublisher
            .sink { productId, status in actions.refundRequestCompleted(productId, status) }
            .store(in: &cancellables)
    }

    @MainActor
    private func subscribeToOtherActions() {
        actionWrapper.feedbackSurveyCompletedPublisher
            .sink { actions.feedbackSurveyCompleted($0) }
            .store(in: &cancellables)

        actionWrapper.managementOptionSelectedPublisher
            .sink { actions.managementOptionSelected($0) }
            .store(in: &cancellables)

        actionWrapper.promotionalOfferSuccessPublisher
            .sink { actions.promotionalOfferSuccess() }
            .store(in: &cancellables)

        actionWrapper.promotionalOfferSucceededPublisher
            .sink { customerInfo, transaction, offerId in
                actions.promotionalOfferSucceeded(customerInfo, transaction, offerId)
            }
            .store(in: &cancellables)

        actionWrapper.showingChangePlansPublisher
            .sink { if let id = $0 { actions.changePlansSelected(id) } }
            .store(in: &cancellables)

        actionWrapper.customActionSelectedPublisher
            .sink { actionId, purchaseId in actions.customActionSelected(actionId, purchaseId) }
            .store(in: &cancellables)
    }
}

#endif
