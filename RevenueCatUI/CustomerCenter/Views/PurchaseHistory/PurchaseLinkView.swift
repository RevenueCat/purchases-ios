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
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    @State var productName: String?
    let purchaseInfo: PurchaseInfo

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(productName ?? purchaseInfo.productIdentifier)
                    .font(.headline)

                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let price = purchaseInfo.paidPrice {
                Text(price)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
        }
        .onAppear {
            Task {
                guard
                    let product = await Purchases.shared.products([purchaseInfo.productIdentifier]).first
                else {
                    return
                }

                productName = product.localizedTitle
            }
        }
    }

    private var purchasedOnLocalized: String {
        localization.commonLocalizedString(for: .purchaseInfoPurchasedOnDate)
            .replacingOccurrences(of: L10n.date, with: formattedDate(purchaseInfo.purchaseDate))
    }

    private var dateString: String {
        guard let expiresDate = purchaseInfo.expiresDate else {
            return purchasedOnLocalized
        }

        guard purchaseInfo.isActive else {
            return localization.commonLocalizedString(for: .purchaseInfoExpiredOnDate)
                .replacingOccurrences(of: L10n.date, with: formattedDate(expiresDate))
        }

        return purchaseInfo.willRenew
        ? localization.commonLocalizedString(for: .purchaseInfoRenewsOnDate)
            .replacingOccurrences(of: L10n.date, with: formattedDate(expiresDate))
        : localization.commonLocalizedString(for: .purchaseInfoExpiresOnDate)
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
