//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionDetailsView.swift
//
//
//  Created by Cody Kerns on 8/12/24.
//

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsView: View {

    let purchaseInformation: PurchaseInformation
    let refundRequestStatus: RefundRequestStatus?
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SubscriptionDetailsHeader(purchaseInformation: purchaseInformation, localization: localization)
                .padding(.bottom, 10)

            Divider()
                .padding(.bottom)

            VStack(alignment: .leading, spacing: 16.0) {
                if let durationTitle = purchaseInformation.durationTitle {
                    IconLabelView(
                        iconName: "coloncurrencysign.arrow.circlepath",
                        label: localization[.billingCycle],
                        value: durationTitle
                    )
                }

                let priceValue: String? = {
                    switch purchaseInformation.price {
                    case .free:
                        return localization[.free]
                    case .paid(let localizedPrice):
                        return localizedPrice
                    case .unknown:
                        return nil
                    }
                }()

                if let price = priceValue {
                    IconLabelView(
                        iconName: "coloncurrencysign",
                        label: localization[.currentPrice],
                        value: price
                    )
                }

                if let expirationOrRenewal = purchaseInformation.expirationOrRenewal {
                    switch expirationOrRenewal.date {
                    case .never:
                        IconLabelView(
                            iconName: "calendar",
                            label: label(for: expirationOrRenewal),
                            value: localization[.never]
                        )
                    case .date(let value):
                        IconLabelView(
                            iconName: "calendar",
                            label: label(for: expirationOrRenewal),
                            value: value
                        )
                    }
                }

                if let refundRequestStatus = refundRequestStatus,
                   let refundStatusMessage = refundStatusMessage(for: refundRequestStatus) {
                    IconLabelView(
                        iconName: "arrowshape.turn.up.backward",
                        label: localization[.refundStatus],
                        value: refundStatusMessage
                    )
                }
            }
        }
        .padding(.vertical, 8.0)
    }

    private func refundStatusMessage(for status: RefundRequestStatus) -> String? {
        switch status {
        case .error:
            return localization[.refundErrorGeneric]
        case .success:
            return localization[.refundGranted]
        case .userCancelled:
            return nil
        @unknown default:
            return nil
        }
    }

    private func label(for expirationOrRenewal: PurchaseInformation.ExpirationOrRenewal) -> String {
        switch expirationOrRenewal.label {
        case .nextBillingDate:
            return localization[.nextBillingDate]
        case .expires:
            return localization[.expires]
        case .expired:
            return localization[.expired]
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsHeader: View {
    let purchaseInformation: PurchaseInformation
    let localization: CustomerCenterConfigData.Localization

    var body: some View {
        VStack(alignment: .leading) {
            if let title = purchaseInformation.title {
                Text(title)
                    .font(.headline)
            }

            let explanation = getSubscriptionExplanation(from: purchaseInformation, localization: localization)

            Text(explanation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }

    private func getSubscriptionExplanation(from purchaseInformation: PurchaseInformation,
                                            localization: CustomerCenterConfigData.Localization) -> String {
        switch purchaseInformation.explanation {
        case .promotional:
            return localization[.youHavePromo]
        case .earliestRenewal:
            return localization[.subEarliestRenewal]
        case .earliestExpiration:
            return localization[.subEarliestExpiration]
        case .expired:
            return localization[.subExpired]
        case .lifetime:
            return localization[.youHaveLifetime]
        case .google:
            return localization[.googleSubscriptionManage]
        case .web:
            return localization[.webSubscriptionManage]
        case .otherStorePurchase:
            return localization[.pleaseContactSupportToManage]
        case .amazon:
            return localization[.amazonSubscriptionManage]
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct IconLabelView: View {
    let iconName: String
    let label: String
    let value: String

    private let iconWidth = 22.0

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: iconName)
                .accessibilityHidden(true)
                .frame(width: iconWidth)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.body)
            }
        }
    }
}

#if DEBUG

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsView_Previews: PreviewProvider {

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            SubscriptionDetailsView(
                purchaseInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
                refundRequestStatus: .success
            )
            .preferredColorScheme(colorScheme)
            .previewDisplayName("Subscription Details - Monthly - \(colorScheme)")
            .padding()
        }
    }

}

#endif

#endif
