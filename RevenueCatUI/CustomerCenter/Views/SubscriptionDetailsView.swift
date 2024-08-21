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

#if CUSTOMER_CENTER_ENABLED

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsView: View {

    let iconWidth = 22.0
    let subscriptionInformation: SubscriptionInformation
    let localization: CustomerCenterConfigData.Localization
    let refundRequestStatusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading) {
                Text("\(subscriptionInformation.title)")
                    .font(.headline)

                let explanation = subscriptionInformation.active ? (
                     subscriptionInformation.willRenew ?
                            localization.commonLocalizedString(for: .subEarliestRenewal) :
                            localization.commonLocalizedString(for: .subEarliestExpiration)
                    ) : localization.commonLocalizedString(for: .subExpired)

                Text("\(explanation)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }.padding([.bottom], 10)

            Divider()
                .padding(.bottom)

            VStack(alignment: .leading, spacing: 16.0) {
                HStack(alignment: .center) {
                    Image(systemName: "coloncurrencysign.arrow.circlepath")
                        .accessibilityHidden(true)
                        .frame(width: iconWidth)
                    VStack(alignment: .leading) {
                        Text(localization.commonLocalizedString(for: .billingCycle))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("\(subscriptionInformation.durationTitle)")
                            .font(.body)
                    }
                }

                HStack(alignment: .center) {
                    Image(systemName: "coloncurrencysign")
                        .accessibilityHidden(true)
                        .frame(width: iconWidth)
                    VStack(alignment: .leading) {
                        Text(localization.commonLocalizedString(for: .currentPrice))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("\(subscriptionInformation.price)")
                            .font(.body)
                    }
                }

                if let nextRenewal =  subscriptionInformation.expirationDateString {

                    let expirationString = subscriptionInformation.active ? (
                        subscriptionInformation.willRenew ?
                            localization.commonLocalizedString(for: .nextBillingDate) :
                            localization.commonLocalizedString(for: .expires)
                    ) : localization.commonLocalizedString(for: .expired)

                    HStack(alignment: .center) {
                        Image(systemName: "calendar")
                            .accessibilityHidden(true)
                            .frame(width: iconWidth)
                        VStack(alignment: .leading) {
                            Text("\(expirationString)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text("\(String(describing: nextRenewal))")
                                .font(.body)
                        }
                    }
                }

                if let refundRequestStatusMessage = refundRequestStatusMessage {
                    HStack(alignment: .center) {
                        Image(systemName: "arrowshape.turn.up.backward")
                            .accessibilityHidden(true)
                            .frame(width: iconWidth)
                        VStack(alignment: .leading) {
                            Text(localization.commonLocalizedString(for: .refundStatus))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text("\(refundRequestStatusMessage)")
                                .font(.body)
                        }
                    }
                }
            }

        }
        .padding(.vertical, 8.0)
        .background(Color(UIColor.tertiarySystemBackground))
    }

}

#if DEBUG

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsView_Previews: PreviewProvider {

    static var previews: some View {
        SubscriptionDetailsView(
            subscriptionInformation: CustomerCenterConfigTestData.subscriptionInformationMonthlyRenewing,
            localization: CustomerCenterConfigTestData.customerCenterData.localization,
            refundRequestStatusMessage: "Success"
        )
        .previewDisplayName("Subscription Details - Monthly")
        .padding()

    }

}

#endif

#endif

#endif
