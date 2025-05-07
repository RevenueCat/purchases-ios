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
//  Created by Facundo Menzella on 7/5/25.

import SwiftUI
import RevenueCat

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchaseInformationCardView: View {

    private let title: String
    private let subtitle: String
    private let storeTitle: String

    init(purchaseInformation: PurchaseInformation, localization: CustomerCenterConfigData.Localization) {
        if purchaseInformation.title?.isEmpty == true {
            self.title = purchaseInformation.productIdentifier
        } else {
            self.title = purchaseInformation.title ?? ""
        }

        self.subtitle = purchaseInformation.billingInformation(localizations: localization)
        self.storeTitle = localization[purchaseInformation.store.localizationKey]
    }

    init(
        title: String,
        subtitle: String,
        storeTitle: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.storeTitle = storeTitle
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

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                Text(storeTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        } content: {
            Image(systemName: "chevron.forward")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundStyle(.secondary)
                .font(Font.system(size: 12, weight: .bold))
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchaseInformationCardView_Previews: PreviewProvider {

    // swiftlint:disable force_unwrapping
    static var previews: some View {
        ScrollView {
            PurchaseInformationCardView(
                title: "Product name",
                subtitle: "Renews 24 May for $19.99",
                storeTitle: Store.appStore.localizationKey.rawValue
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding([.leading, .trailing])

            PurchaseInformationCardView(
                title: "Product name",
                subtitle: "Renews 24 May for $19.99",
                storeTitle: Store.playStore.localizationKey.rawValue
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
