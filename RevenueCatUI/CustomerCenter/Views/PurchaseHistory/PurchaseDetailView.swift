//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseHistoryView.swift
//
//  Created by Facundo Menzella on 14/1/25.
//

#if os(iOS)
@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
struct PurchaseDetailView: View {

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @StateObject var viewModel: PurchaseDetailViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.items) { detailItem in
                    CompatibilityLabeledContent(
                        localization[detailItem.label],
                        content: content(detailItem: detailItem)
                    )
                }
            } footer: {
                if let ownershipKey = viewModel.localizedOwnership {
                    Text(localization[ownershipKey])
                }
            }

            if !viewModel.debugItems.isEmpty {
                Section(localization[.debugHeaderTitle]) {
                    ForEach(viewModel.debugItems) { detailItem in
                        CompatibilityLabeledContent(
                            localization[detailItem.label],
                            content: content(detailItem: detailItem)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.didAppear(localization: localization)
        }
    }

    func content(detailItem: PurchaseDetailItem) -> String {
        switch detailItem {
        case let .productName(name):
            return name

        case let .paidPrice(price):
            return price ?? "-"

        case .status(let value),
                .periodType(let value),
                .store(let value):
            return localization[value]

        case .latestPurchaseDate(let value),
                .originalPurchaseDate(let value),
                .expiresDate(let value),
                .nextRenewalDate(let value),
                .unsubscribeDetectedAt(let value),
                .billingIssuesDetectedAt(let value),
                .gracePeriodExpiresDate(let value),
                .refundedAtDate(let value),
                .productID(let value),
                .transactionID(let value):
            return value

        case .sandbox(let value):
            return value
            ? localization[.answerYes]
            : localization[.answerNo]
        }
    }
}

#endif
