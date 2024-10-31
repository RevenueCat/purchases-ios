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

    let subscriptionInformation: SubscriptionInformation
    let refundRequestStatus: RefundRequestStatus?
    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SubscriptionDetailsHeader(subscriptionInformation: subscriptionInformation, localization: localization)
                .padding(.bottom, 10)

            Divider()
                .padding(.bottom)

            VStack(alignment: .leading, spacing: 16.0) {
                if let durationTitle = subscriptionInformation.durationTitle {
                    IconLabelView(
                        iconName: "coloncurrencysign.arrow.circlepath",
                        label: localization.commonLocalizedString(for: .billingCycle),
                        value: durationTitle
                    )
                }

                let priceValue: String? = {
                    switch subscriptionInformation.price {
                    case .free:
                        return localization.commonLocalizedString(for: .free)
                    case .paid(let localizedPrice):
                        return localizedPrice
                    case .unknown:
                        return nil
                    }
                }()

                if let price = priceValue {
                    IconLabelView(
                        iconName: "coloncurrencysign",
                        label: localization.commonLocalizedString(for: .currentPrice),
                        value: price
                    )
                }

                if let expirationOrRenewal = subscriptionInformation.expirationOrRenewal {
                    switch expirationOrRenewal.date {
                    case .never:
                        IconLabelView(
                            iconName: "calendar",
                            label: label(for: expirationOrRenewal),
                            value: localization.commonLocalizedString(for: .never)
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
                        label: localization.commonLocalizedString(for: .refundStatus),
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
            return localization.commonLocalizedString(for: .refundErrorGeneric)
        case .success:
            return localization.commonLocalizedString(for: .refundGranted)
        case .userCancelled:
            return localization.commonLocalizedString(for: .refundCanceled)
        @unknown default:
            return nil
        }
    }

    private func label(for expirationOrRenewal: SubscriptionInformation.ExpirationOrRenewal) -> String {
        switch expirationOrRenewal.label {
        case .nextBillingDate:
            return localization.commonLocalizedString(for: .nextBillingDate)
        case .expires:
            return localization.commonLocalizedString(for: .expires)
        case .expired:
            return localization.commonLocalizedString(for: .expired)
        }
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsHeader: View {
    let subscriptionInformation: SubscriptionInformation
    let localization: CustomerCenterConfigData.Localization

    var body: some View {
        VStack(alignment: .leading) {
            if let title = subscriptionInformation.title {
                Text(title)
                    .font(.headline)
            }

            let explanation = getSubscriptionExplanation(from: subscriptionInformation, localization: localization)

            Text(explanation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }

    private func getSubscriptionExplanation(from subscriptionInformation: SubscriptionInformation,
                                            localization: CustomerCenterConfigData.Localization) -> String {
        switch subscriptionInformation.explanation {
        case .promotional:
            return localization.commonLocalizedString(for: .youHavePromo)
        case .earliestRenewal:
            return localization.commonLocalizedString(for: .subEarliestRenewal)
        case .earliestExpiration:
            return localization.commonLocalizedString(for: .subEarliestExpiration)
        case .expired:
            return localization.commonLocalizedString(for: .subExpired)
        case .lifetime:
            return localization.commonLocalizedString(for: .youHaveLifetime)
        case .google:
            return localization.commonLocalizedString(for: .googleSubscriptionManage)
        case .web:
            return localization.commonLocalizedString(for: .webSubscriptionManage)
        case .otherStorePurchase:
            return localization.commonLocalizedString(for: .pleaseContactSupportToManage)
        case .amazon:
            return localization.commonLocalizedString(for: .amazonSubscriptionManage)
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
                subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
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
