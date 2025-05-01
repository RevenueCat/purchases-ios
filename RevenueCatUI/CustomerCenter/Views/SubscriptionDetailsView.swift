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

            Text(purchaseInformation.billingInformation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
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
}

#endif
