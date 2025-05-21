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

    @Published var selectedPurchase: PurchaseInformation?

    @Published var customerInfo: CustomerInfo? {
        didSet {
            isLoading = false
        }
    }
    @Published var errorMessage: String?
    @Published var isLoading: Bool = true

    var activeSubscriptions: [PurchaseInformation] = []
    var inactiveSubscriptions: [PurchaseInformation] = []
    var nonSubscriptions: [PurchaseInformation] = []

    private(set) var purchasesProvider: CustomerCenterPurchasesType
    private let customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType

    init(
        selectedPurchase: PurchaseInformation? = nil,
        customerInfo: CustomerInfo? = nil,
        errorMessage: String? = nil,
        isLoading: Bool = true,
        activeSubscriptions: [PurchaseInformation] = [],
        inactiveSubscriptions: [PurchaseInformation] = [],
        nonSubscriptions: [PurchaseInformation] = [],
        purchasesProvider: CustomerCenterPurchasesType,
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType = CustomerCenterStoreKitUtilities()
    ) {
        self.selectedPurchase = selectedPurchase
        self.customerInfo = customerInfo
        self.errorMessage = errorMessage
        self.isLoading = isLoading
        self.activeSubscriptions = activeSubscriptions
        self.inactiveSubscriptions = inactiveSubscriptions
        self.nonSubscriptions = nonSubscriptions
        self.purchasesProvider = purchasesProvider
        self.customerCenterStoreKitUtilities = customerCenterStoreKitUtilities
    }

    func didAppear() async {
        guard customerInfo == nil else {
            await fetchCustomerInfo()
            return
        }

    }
}

@available(iOS 15.0, *)
private extension PurchaseHistoryViewModel {
    func fetchCustomerInfo() async {
        do {
            let customerInfo = try await self.purchasesProvider.customerInfo()
            await updateActiveAndNonActiveSubscriptions(customerInfo: customerInfo)
            await MainActor.run {
                self.customerInfo = customerInfo
            }
        } catch {
            self.activeSubscriptions = []
            self.inactiveSubscriptions = []
            self.nonSubscriptions = []

            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func updateActiveAndNonActiveSubscriptions(customerInfo: CustomerInfo) async {
        var activeSubscriptions: [PurchaseInformation] = []
        var inactiveSubscriptions: [PurchaseInformation] = []
        var nonSubscriptions: [PurchaseInformation] = []

        for subscription in customerInfo.subscriptionsByProductIdentifier where subscription.value.isActive {
            let entitlement = customerInfo.entitlements.all.values
                .first(where: { $0.productIdentifier == subscription.value.productIdentifier })

            activeSubscriptions.append(await .from(
                transaction: subscription.value,
                entitlement: entitlement,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities
            ))
        }
        self.activeSubscriptions = activeSubscriptions.sorted(by: { sub1, sub2 in
            sub1.latestPurchaseDate < sub2.latestPurchaseDate
        })

        for subscription in customerInfo.subscriptionsByProductIdentifier where !subscription.value.isActive {
            let entitlement = customerInfo.entitlements.all.values
                .first(where: { $0.productIdentifier == subscription.value.productIdentifier })

            inactiveSubscriptions.append(await .from(
                transaction: subscription.value,
                entitlement: entitlement,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities
            ))
        }
        self.inactiveSubscriptions = inactiveSubscriptions.sorted(by: { sub1, sub2 in
            sub1.latestPurchaseDate < sub2.latestPurchaseDate
        })

        for purchase in customerInfo.nonSubscriptions {
            let entitlement = customerInfo.entitlements.all.values
                .first(where: { $0.productIdentifier == purchase.productIdentifier })

            nonSubscriptions.append(await .from(
                transaction: purchase,
                entitlement: entitlement,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities
            ))
        }
        self.nonSubscriptions = nonSubscriptions.sorted(by: { sub1, sub2 in
            sub1.latestPurchaseDate < sub2.latestPurchaseDate
        })
    }
}

#endif
