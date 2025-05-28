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
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor class RestorePurchasesAlertViewModel: ObservableObject {

    @Published
    var alertType: RestorePurchasesAlertViewModel.AlertType = .loading

    private let actionWrapper: CustomerCenterActionWrapper

    enum AlertType: Identifiable {
        case loading, purchasesRecovered, purchasesNotFound
        var id: Self { self }
    }

    init(
        purchasesProvider: CustomerCenterPurchasesType = CustomerCenterPurchases(),
        actionWrapper: CustomerCenterActionWrapper
    ) {
        self.actionWrapper = actionWrapper
    }

    func performRestore(purchasesProvider: CustomerCenterPurchasesType) async {
        self.alertType = .loading
        self.actionWrapper.handleAction(.restoreStarted)

        do {
            // In case the restore finishes instantly, we make sure it lasts at least 0.5 seconds
            let (customerInfo, _) = try await (purchasesProvider.restorePurchases(),
                                               Task.sleep(nanoseconds: 500_000_000))
            self.actionWrapper.handleAction(.restoreCompleted(customerInfo))

            let hasPurchases = !customerInfo.activeSubscriptions.isEmpty || !customerInfo.nonSubscriptions.isEmpty
            self.alertType = hasPurchases ? .purchasesRecovered : .purchasesNotFound
        } catch {
            self.actionWrapper.handleAction(.restoreFailed(error))
            self.alertType = .purchasesNotFound
        }
    }

}
