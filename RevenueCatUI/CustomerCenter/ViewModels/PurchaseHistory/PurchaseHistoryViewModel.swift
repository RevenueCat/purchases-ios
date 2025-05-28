//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHistoryViewModel.swift
//
//
//  Created by Facundo Menzella on 13/1/25.
//

import Foundation
import SwiftUI

import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PurchaseHistoryViewModel: ObservableObject {

    @Published var selectedPurchase: PurchaseInfo?

    @Published var customerInfo: CustomerInfo? {
        didSet {
            isLoading = false
            updateActiveAndNonActiveSubscriptions()
        }
    }
    @Published var errorMessage: String?
    @Published var isLoading: Bool = true

    var activeSubscriptions: [PurchaseInfo] = []
    var inactiveSubscriptions: [PurchaseInfo] = []
    var nonSubscriptions: [PurchaseInfo] = []

    var isEmpty: Bool {
        activeSubscriptions.isEmpty && inactiveSubscriptions.isEmpty && nonSubscriptions.isEmpty
    }

    let purchasesProvider: CustomerCenterPurchasesType

    init(
        selectedPurchase: PurchaseInfo? = nil,
        customerInfo: CustomerInfo? = nil,
        errorMessage: String? = nil,
        isLoading: Bool = true,
        activeSubscriptions: [PurchaseInfo] = [],
        inactiveSubscriptions: [PurchaseInfo] = [],
        nonSubscriptions: [PurchaseInfo] = [],
        purchasesProvider: CustomerCenterPurchasesType
    ) {
        self.selectedPurchase = selectedPurchase
        self.customerInfo = customerInfo
        self.errorMessage = errorMessage
        self.isLoading = isLoading
        self.activeSubscriptions = activeSubscriptions
        self.inactiveSubscriptions = inactiveSubscriptions
        self.nonSubscriptions = nonSubscriptions
        self.purchasesProvider = purchasesProvider
    }

    func didAppear() async {
        await fetchCustomerInfo()
    }
}

@available(iOS 15.0, *)
private extension PurchaseHistoryViewModel {
    func fetchCustomerInfo() async {
        do {
            let customerInfo = try await self.purchasesProvider.customerInfo()
            await MainActor.run {
                self.customerInfo = customerInfo
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func updateActiveAndNonActiveSubscriptions() {
        activeSubscriptions = customerInfo.map {
            $0.subscriptionsByProductIdentifier
                .filter { $0.value.isActive }
                .values
                .sorted(by: { sub1, sub2 in
                    sub1.purchaseDate < sub2.purchaseDate
                })
                .map {
                    PurchaseInfo.subscription($0)
                }
        } ?? []

        inactiveSubscriptions = customerInfo.map {
            $0.subscriptionsByProductIdentifier
                .filter { !$0.value.isActive }
                .values
                .sorted(by: { sub1, sub2 in
                    sub1.purchaseDate < sub2.purchaseDate
                })
                .map {
                    PurchaseInfo.subscription($0)
                }
        } ?? []

        nonSubscriptions = customerInfo?.nonSubscriptions.map {
            .nonSubscription($0)
        } ?? []
    }
}

#endif
