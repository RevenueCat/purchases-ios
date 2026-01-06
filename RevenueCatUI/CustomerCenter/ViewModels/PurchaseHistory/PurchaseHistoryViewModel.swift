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
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PurchaseHistoryViewModel: ObservableObject {

    @Published
    var selectedPurchase: PurchaseInformation?

    @Published
    var errorMessage: String?

    @Published
    var isLoading: Bool = true

    @Published
    var activeSubscriptions: [PurchaseInformation] = []

    @Published
    var inactiveSubscriptions: [PurchaseInformation] = []

    @Published
    var nonSubscriptions: [PurchaseInformation] = []

    var isEmpty: Bool {
        activeSubscriptions.isEmpty && inactiveSubscriptions.isEmpty && nonSubscriptions.isEmpty
    }

    let purchasesProvider: CustomerCenterPurchasesType
    private let customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType
    private let localization: CustomerCenterConfigData.Localization

    init(
        selectedPurchase: PurchaseInformation? = nil,
        errorMessage: String? = nil,
        isLoading: Bool = true,
        activeSubscriptions: [PurchaseInformation] = [],
        inactiveSubscriptions: [PurchaseInformation] = [],
        nonSubscriptions: [PurchaseInformation] = [],
        purchasesProvider: CustomerCenterPurchasesType,
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType = CustomerCenterStoreKitUtilities(),
        localization: CustomerCenterConfigData.Localization
    ) {
        self.selectedPurchase = selectedPurchase
        self.errorMessage = errorMessage
        self.isLoading = isLoading
        self.activeSubscriptions = activeSubscriptions
        self.inactiveSubscriptions = inactiveSubscriptions
        self.nonSubscriptions = nonSubscriptions
        self.purchasesProvider = purchasesProvider
        self.customerCenterStoreKitUtilities = customerCenterStoreKitUtilities
        self.localization = localization
    }

    func didAppear() async {
        await MainActor.run {
            isLoading = true
        }

        await fetchCustomerInfo()

        await MainActor.run {
            isLoading = false
        }
    }
}

@available(iOS 15.0, *)
private extension PurchaseHistoryViewModel {
    func fetchCustomerInfo() async {
        do {
            let customerInfo = try await self.purchasesProvider.customerInfo()
            let (active, inactive, nonSubscriptions) = await updateActiveAndNonActiveSubscriptions(
                customerInfo: customerInfo
            )
            await MainActor.run {
                self.activeSubscriptions = active
                self.inactiveSubscriptions = inactive
                self.nonSubscriptions = nonSubscriptions
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

    func updateActiveAndNonActiveSubscriptions(customerInfo: CustomerInfo) async -> (
        [PurchaseInformation],
        [PurchaseInformation],
        [PurchaseInformation]
    ) {
        var activeSubscriptions: [PurchaseInformation] = []
        var inactiveSubscriptions: [PurchaseInformation] = []
        var nonSubscriptions: [PurchaseInformation] = []

        for subscription in customerInfo.subscriptionsByProductIdentifier where subscription.value.isActive {
            await activeSubscriptions.append(.from(
                transaction: subscription.value,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                changePlans: [], // ignored on purpose because there's no change plan flow from history
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                localization: localization
            ))
        }

        activeSubscriptions = activeSubscriptions.sorted(by: { sub1, sub2 in
            sub1.latestPurchaseDate < sub2.latestPurchaseDate
        })

        for subscription in customerInfo.subscriptionsByProductIdentifier where !subscription.value.isActive {
            await inactiveSubscriptions.append(.from(
                transaction: subscription.value,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                // ignored on purpose because there's no change plan flow from purchase history
                changePlans: [],
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                localization: localization
            ))
        }

        inactiveSubscriptions = inactiveSubscriptions.sorted(by: { sub1, sub2 in
            sub1.latestPurchaseDate < sub2.latestPurchaseDate
        })

        for purchase in customerInfo.nonSubscriptions {
            await nonSubscriptions.append(.from(
                transaction: purchase,
                customerInfo: customerInfo,
                purchasesProvider: purchasesProvider,
                changePlans: [], // ignored on purpose because there's no change plan flow from purchase history
                customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
                localization: localization
            ))
        }
        nonSubscriptions = nonSubscriptions.sorted(by: { sub1, sub2 in
            sub1.latestPurchaseDate < sub2.latestPurchaseDate
        })

        return (activeSubscriptions, inactiveSubscriptions, nonSubscriptions)
    }
}

#endif
