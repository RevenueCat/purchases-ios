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
//  Created by Facundo Menzella on 14/1/25.
//

import Foundation
import SwiftUI

import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PurchaseDetailViewModel: ObservableObject {

    @Published var items: [PurchaseDetailItem] = []
    var debugItems: [PurchaseDetailItem] = []

    var localizedOwnership: CCLocalizedString? {
        switch purchaseInfo {
        case .subscription(let subscriptionInfo):
            return subscriptionInfo.ownershipType == .familyShared
                ? .sharedThroughFamilyMember
                : nil
        case .nonSubscription:
            return nil
        }
    }

    init(purchaseInfo: PurchaseInfo, purchasesProvider: CustomerCenterPurchasesType) {
        self.purchaseInfo = purchaseInfo
        self.purchasesProvider = purchasesProvider
    }

    func didAppear() async {
        await fetchProduct()
    }

    // MARK: - Private

    private let purchaseInfo: PurchaseInfo
    private let purchasesProvider: CustomerCenterPurchasesType
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension PurchaseDetailViewModel {

    func fetchProduct() async {
        guard
            let product = await self.purchasesProvider.products([purchaseInfo.productIdentifier]).first
        else {
            return
        }

        await MainActor.run {
            var items: [PurchaseDetailItem] = [
                .productName(product.localizedTitle)
            ]

            items.append(contentsOf: purchaseInfo.purchaseDetailItems)
            self.debugItems = purchaseInfo.purchaseDetailDebugItems
            self.items = items
        }
    }
}

#endif
