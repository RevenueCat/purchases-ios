//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseInformationCardView.swift
//
//  Created by Facundo Menzella on 13/5/25.

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchaseInformationCardView: View {

    private let title: String
    private let subtitle: String?
    private let storeTitle: String
    private let showChevron: Bool

    init(
        title: String,
        storeTitle: String,
        subtitle: String? = nil,
        showChevron: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.storeTitle = storeTitle
        self.showChevron = showChevron
    }

    init(
        purchaseInformation: PurchaseInformation,
        localization: CustomerCenterConfigData.Localization,
        showChevron: Bool = true
    ) {
        self.title = purchaseInformation.title

        if let renewalDate = purchaseInformation.renewalDate {
            self.subtitle = purchaseInformation.priceRenewalString(
                date: renewalDate,
                localizations: localization
            )
        } else if let expirationDate = purchaseInformation.expirationDate {
            self.subtitle = purchaseInformation.expirationString(
                date: expirationDate,
                localizations: localization
            )
        } else {
            self.subtitle = nil
        }

        self.storeTitle = localization[purchaseInformation.store.localizationKey]
        self.showChevron = showChevron
    }

    var body: some View {
        CompatibilityLabeledContent {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.bottom, 8)
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                        .frame(alignment: .leading)
                        .multilineTextAlignment(.leading)
                }

                Text(storeTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        } content: {
            if showChevron {
                Image(systemName: "chevron.forward")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.secondary)
                    .font(Font.system(size: 12, weight: .bold))
            }
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchaseInformationCardView_Previews: PreviewProvider {

    static var previews: some View {
        ScrollView {
            PurchaseInformationCardView(
                title: "Product name",
                storeTitle: Store.appStore.localizationKey.rawValue,
                subtitle: "Renews 24 May for $19.99"
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding([.leading, .trailing])

            PurchaseInformationCardView(
                title: "Product name",
                storeTitle: Store.playStore.localizationKey.rawValue,
                subtitle: "Renews 24 May for $19.99"
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding([.leading, .trailing])
        }
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
