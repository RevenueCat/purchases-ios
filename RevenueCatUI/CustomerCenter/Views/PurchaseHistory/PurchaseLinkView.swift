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
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
struct PurchaseLinkView: View {

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @State var productName: String?
    let purchaseInfo: PurchaseInfo
    let purchasesProvider: CustomerCenterPurchasesType

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(productName ?? purchaseInfo.productIdentifier)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let price = purchaseInfo.paidPrice {
                Text(price)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .tint(colorScheme == .dark ? .white : .black)
        .onAppear {
            Task {
                guard
                    let product = await purchasesProvider.products([purchaseInfo.productIdentifier]).first
                else {
                    return
                }

                productName = product.localizedTitle
            }
        }
    }

    private var purchasedOnLocalized: String {
        localization[.purchaseInfoPurchasedOnDate]
            .replacingOccurrences(of: L10n.date, with: formattedDate(purchaseInfo.purchaseDate))
    }

    private var dateString: String {
        guard let expiresDate = purchaseInfo.expiresDate else {
            return purchasedOnLocalized
        }

        guard purchaseInfo.isActive else {
            return localization[.purchaseInfoExpiredOnDate]
                .replacingOccurrences(of: L10n.date, with: formattedDate(expiresDate))
        }

        return purchaseInfo.willRenew
        ? localization[.purchaseInfoRenewsOnDate]
            .replacingOccurrences(of: L10n.date, with: formattedDate(expiresDate))
        : localization[.purchaseInfoExpiresOnDate]
            .replacingOccurrences(of: L10n.date, with: formattedDate(expiresDate))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

private enum L10n {
    static let date = "{{ date }}"
}

#endif
