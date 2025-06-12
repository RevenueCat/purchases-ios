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

@_spi(Internal) import RevenueCat

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
final class PurchaseDetailViewModel: ObservableObject {

    @Published var items: [PurchaseDetailItem] = []
    var debugItems: [PurchaseDetailItem] = []

    var localizedOwnership: CCLocalizedString? {
        if purchaseInfo.ownershipType == .familyShared {
            return .sharedThroughFamilyMember
        }

        return nil
    }

    init(purchaseInfo: PurchaseInformation) {
        self.purchaseInfo = purchaseInfo
    }

    func didAppear(localization: CustomerCenterConfigData.Localization) {
        var items: [PurchaseDetailItem] = [
            .productName(purchaseInfo.title)
        ]

        items.append(contentsOf: purchaseInfo.purchaseDetailItems(localization: localization))
        self.debugItems = purchaseInfo.purchaseDetailDebugItems
        self.items = items
    }

    // MARK: - Private

    private let purchaseInfo: PurchaseInformation
}

#endif
