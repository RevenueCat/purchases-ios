//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RestorePurchasesAlertViewModel.swift
//
//  Created by Cesar de la Vega on 28/3/25.

import Foundation
import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor class RestorePurchasesAlertViewModel: ObservableObject {

    private let purchasesProvider: CustomerCenterPurchasesType
    private let actionWrapper: CustomerCenterActionWrapper
    @Published var state: CustomerCenterViewState

    enum AlertType: Identifiable {
        case loading, purchasesRecovered, purchasesNotFound
        var id: Self { self }
    }

    init(
        purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases(),
        actionWrapper: CustomerCenterActionWrapper,
        state: Binding<CustomerCenterViewState>
    ) {
        self.purchasesProvider = purchasesProvider
        self.actionWrapper = actionWrapper
        self.state = state.wrappedValue
    }

    func performRestore() async -> AlertType {
        self.actionWrapper.handleAction(.restoreStarted)

        do {
            let customerInfo = try await purchasesProvider.restorePurchases()
            self.actionWrapper.handleAction(.restoreCompleted(customerInfo))

            let hasPurchases = !customerInfo.activeSubscriptions.isEmpty || !customerInfo.nonSubscriptions.isEmpty

            self.state = .notLoaded

            return hasPurchases ? .purchasesRecovered : .purchasesNotFound
        } catch {
            self.actionWrapper.handleAction(.restoreFailed(error))
            return .purchasesNotFound
        }
    }
}
