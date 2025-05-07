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
        SubscriptionDetailsHeader(
            purchaseInformation: purchaseInformation,
            refundRequestStatus: refundRequestStatus,
            localization: localization
        )
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SubscriptionDetailsHeader: View {
    let purchaseInformation: PurchaseInformation
    let refundRequestStatus: RefundRequestStatus?
    let localization: CustomerCenterConfigData.Localization

    var body: some View {
        VStack(alignment: .leading) {
            Text(titleString).font(.title3) +
            Text(statusString.map {" " +  "(\($0))"} ?? "")
                .font(.subheadline)

            Text(purchaseInformation.billingInformation(localizations: localization))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func getSubscriptionExplanation(from purchaseInformation: PurchaseInformation,
                                            localization: CustomerCenterConfigData.Localization) -> String? {
        guard purchaseInformation.expirationOrRenewal != nil else {
            return nil
        }

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
        case .externalWeb:
            return localization[.webSubscriptionManage]
        case .otherStorePurchase:
            return localization[.pleaseContactSupportToManage]
        case .amazon:
            return localization[.amazonSubscriptionManage]
        case .rcWebBilling:
            return localization[.webSubscriptionManage]
        }
    }

    private var titleString: String {
        purchaseInformation.title ?? purchaseInformation.productIdentifier
    }

    private var statusString: String? {
        if let cancelledString {
            return cancelledString
        } else if let refundRequestStatus = refundRequestStatus,
           let refundStatusMessage = refundStatusMessage(for: refundRequestStatus) {
            return refundStatusMessage
        }

        return nil
    }

    private var cancelledString: String? {
        purchaseInformation.isCancelled ? "Cancelled" : nil
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
                purchaseInformation: .monthlyRenewing,
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

