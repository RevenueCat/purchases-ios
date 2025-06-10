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

    @Environment(\.colorScheme)
    private var colorScheme

    private let title: String
    private let subtitle: String?
    private let badge: Badge?

    private let accessibilityIdentifier: String

    private let storeTitle: String

    private let additionalIcon: Image?
    private let additionalInfo: String?

    private let paidPrice: String
    private let showChevron: Bool

    init(
        title: String,
        storeTitle: String,
        paidPrice: String,
        accessibilityIdentifier: String,
        badge: PurchaseInformationCardView.Badge? = nil,
        additionalIcon: Image? = nil,
        additionalInfo: String? = nil,
        subtitle: String? = nil,
        showChevron: Bool = true
    ) {
        self.title = title
        self.paidPrice = paidPrice
        self.subtitle = subtitle
        self.badge = badge
        self.additionalIcon = additionalIcon
        self.additionalInfo = additionalInfo
        self.storeTitle = storeTitle
        self.showChevron = showChevron
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    init(
        purchaseInformation: PurchaseInformation,
        localization: CustomerCenterConfigData.Localization,
        accessibilityIdentifier: String,
        refundStatus: RefundRequestStatus? = nil,
        showChevron: Bool = true
    ) {
        self.title = purchaseInformation.title
        self.accessibilityIdentifier = accessibilityIdentifier

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
            self.subtitle = purchaseInformation.pricePaidString(localizations: localization)
        }

        self.additionalIcon = refundStatus?.icon
        self.additionalInfo = refundStatus?.subtitle(localization: localization)

        switch purchaseInformation.pricePaid {
        case .free, .unknown:
            self.paidPrice = ""
        case .nonFree(let pricePaid) where purchaseInformation.shoulShowPricePaid:
            self.paidPrice = pricePaid
        case .nonFree:
            self.paidPrice = ""
        }
        self.storeTitle = localization[purchaseInformation.store.localizationKey]
        self.showChevron = showChevron

        if !purchaseInformation.isActive {
            self.badge = .expired(localization)
        } else if purchaseInformation.isCancelled {
            self.badge = .cancelled(localization)
        } else if purchaseInformation.isTrial, purchaseInformation.pricePaid == .free {
            self.badge = .freeTrial(localization)
        } else if purchaseInformation.isActive {
            self.badge = .active(localization)
        } else {
            self.badge = nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                                .accessibilityIdentifier([accessibilityIdentifier, badge.id].joined(separator: "_"))
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
            .padding()
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground))

            if let additionalInfo, let additionalIcon {
                HStack(alignment: .center, spacing: 12) {
                    additionalIcon
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(.secondary)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)

                    Text(additionalInfo)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .padding()
            }
        }
        .background(Color(colorScheme == .light
                          ? UIColor.secondarySystemFill
                          : UIColor.tertiarySystemBackground))
    }
}

private extension PurchaseInformation {
    var shoulShowPricePaid: Bool {
        renewalPrice != nil || expirationDate != nil
    }
}

private extension RefundRequestStatus {

    var icon: Image? {
        switch self {
        case .error:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .success:
            return Image(systemName: "info.circle.fill")
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }

    func subtitle(
        localization: CustomerCenterConfigData.Localization
    ) -> String? {
        switch self {
        case .error:
            return localization[.refundErrorGeneric]
        case .success:
            return localization[.refundSuccess]
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension PurchaseInformationCardView {

    struct Badge {
        let title: String
        let id: String
        let backgroundColor: Color

        static func cancelled(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.badgeCancelled],
                id: CCLocalizedString.badgeCancelled.rawValue,
                backgroundColor: Color(red: 242 / 256, green: 84 / 256, blue: 91 / 256, opacity: 0.15)
            )
        }

        static func freeTrial(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.badgeFreeTrial],
                id: CCLocalizedString.badgeFreeTrial.rawValue,
                backgroundColor: Color(red: 245 / 256, green: 202 / 256, blue: 92 / 256, opacity: 0.2)
            )
        }

        static func active(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.active],
                id: CCLocalizedString.active.rawValue,
                backgroundColor: Color(red: 52 / 256, green: 199 / 256, blue: 89 / 256, opacity: 0.2)
            )
        }

        static func expired(_ localizations: CustomerCenterConfigData.Localization) -> Badge {
            Badge(
                title: localizations[.expired],
                id: CCLocalizedString.expired.rawValue,
                backgroundColor: Color(red: 242 / 256, green: 242 / 256, blue: 247 / 256, opacity: 0.2)
            )
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
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            ScrollViewWithOSBackground {
                PurchaseInformationCardView(
                    title: "Product name",
                    storeTitle: Store.appStore.localizationKey.rawValue,
                    paidPrice: "$19.99",
                    accessibilityIdentifier: "accessibilityIdentifier",
                    badge: .cancelled(CustomerCenterConfigData.default.localization),
                    subtitle: "Renews 24 May for $19.99"
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    title: "Product name",
                    storeTitle: Store.playStore.localizationKey.rawValue,
                    paidPrice: "$19.99",
                    accessibilityIdentifier: "accessibilityIdentifier",
                    badge: .freeTrial(CustomerCenterConfigData.default.localization),
                    subtitle: "Renews 24 May for $19.99"
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    title: "Product name",
                    storeTitle: Store.playStore.localizationKey.rawValue,
                    paidPrice: "$19.99",
                    accessibilityIdentifier: "accessibilityIdentifier",
                    badge: .active(CustomerCenterConfigData.default.localization),
                    additionalIcon: Image(systemName: "exclamationmark.triangle.fill"),
                    additionalInfo: "Apple has received the refund request Apple has received the refund request",
                    subtitle: "Renews 24 May for $19.99"
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    title: "Product name",
                    storeTitle: Store.playStore.localizationKey.rawValue,
                    paidPrice: "$19.99",
                    accessibilityIdentifier: "accessibilityIdentifier",
                    badge: .active(CustomerCenterConfigData.default.localization),
                    additionalIcon: Image(systemName: "info.circle.fill"),
                    additionalInfo: "An error occurred while processing the refund request. Please try again.",
                    subtitle: "Renews 24 May for $19.99"
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    purchaseInformation: .consumable,
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])

                PurchaseInformationCardView(
                    purchaseInformation: .expired,
                    localization: CustomerCenterConfigData.default.localization,
                    accessibilityIdentifier: "accessibilityIdentifier"
                )
                .cornerRadius(10)
                .padding([.leading, .trailing])
            }
            .preferredColorScheme(colorScheme)
        }
        .environment(\.appearance, CustomerCenterConfigData.default.appearance)
    }

}

#endif

#endif
