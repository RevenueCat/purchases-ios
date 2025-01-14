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

    @Published var selectedActiveSubscrition: SubscriptionInfo?
    @Published var selectedInactiveSubscription: SubscriptionInfo?
    @Published var customerInfo: CustomerInfo? {
        didSet {
            updateActiveAndNonActiveSubscriptions()
        }
    }
    @Published var errorMessage: String?

    var activeSubscriptions: [SubscriptionInfo] = []
    var inactiveSubscriptions: [SubscriptionInfo] = []

    func didAppear() async {
        await fetchCustomerInfo()
    }
}

@available(iOS 15.0, *)
private extension PurchaseHistoryViewModel {
    func fetchCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.customerInfo = customerInfo
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func updateActiveAndNonActiveSubscriptions() {
        activeSubscriptions = customerInfo.map {
            $0.subscriptionsByProductIdentifier
                .filter { $0.value.isActive }
                .values
                .sorted(by: { s1, s2 in
                    s1.purchaseDate < s2.purchaseDate
                })
        } ?? []

        inactiveSubscriptions = customerInfo.map {
            $0.subscriptionsByProductIdentifier
                .filter { !$0.value.isActive }
                .values
                .sorted(by: { s1, s2 in
                    s1.purchaseDate < s2.purchaseDate
                })
        } ?? []
    }
}

#endif
