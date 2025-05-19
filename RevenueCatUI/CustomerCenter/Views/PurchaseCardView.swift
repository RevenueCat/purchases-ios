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
    private let badge: Badge?

    private let storeTitle: String
    private let paidPrice: String
    private let showChevron: Bool

    init(
        title: String,
        storeTitle: String,
        paidPrice: String,
        badge: PurchaseInformationCardView.Badge? = nil,
        subtitle: String? = nil,
        showChevron: Bool = true
    ) {
        self.title = title
        self.paidPrice = paidPrice
        self.subtitle = subtitle
        self.badge = badge
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
        } else if purchaseInformation.expirationDate != nil {
            self.subtitle = purchaseInformation.expirationString(
                localizations: localization
            )
        } else {
            self.subtitle = nil
        }

        switch purchaseInformation.pricePaid {
        case .free, .unknown:
            self.paidPrice = ""
        case .nonFree(let pricePaid):
            self.paidPrice = pricePaid
        }
        self.storeTitle = localization[purchaseInformation.store.localizationKey]
        self.showChevron = showChevron

        if purchaseInformation.isCancelled {
            self.badge = .cancelled(localization[.badgeCancelled])
        } else if purchaseInformation.isTrial, purchaseInformation.pricePaid == .free {
            self.badge = .freeTrial(localization[.badgeFreeTrial])
        } else {
            self.badge = nil
        }
    }

    var body: some View {
        CompatibilityLabeledContent {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(alignment: .center)
                        .multilineTextAlignment(.leading)

                    if let badge {
                        Text(badge.title)
                            .font(.caption2)
                            .bold()
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .background(badge.backgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.bottom, 8)

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
            HStack {
                Text(paidPrice)
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
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PurchaseInformationCardView {
    enum Badge {
        case cancelled(String), freeTrial(String)

        var title: String {
            switch self {
            case let .cancelled(title):
                return title
            case let .freeTrial(title):
                return title
            }
        }

        var backgroundColor: Color {
            switch self {
            case .cancelled:
                return Color(red: 242 / 256, green: 84 / 256, blue: 91 / 256, opacity: 0.15)
            case .freeTrial:
                return Color(red: 245 / 256, green: 202 / 256, blue: 92 / 256, opacity: 0.2)
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
                paidPrice: "$19.99",
                badge: .cancelled("Cancelled"),
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
                paidPrice: "$19.99",
                badge: .freeTrial("Free Trial"),
                subtitle: "Renews 24 May for $19.99"
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 4)
            .padding([.leading, .trailing])

            PurchaseInformationCardView(
                title: "Product name",
                storeTitle: Store.playStore.localizationKey.rawValue,
                paidPrice: "$19.99",
                subtitle: "Renews 24 May for $19.99"
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 4)
            .padding([.leading, .trailing])
        }
        .environment(\.localization, CustomerCenterConfigData.default.localization)
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
