//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigData.HelpPath+PurchaseInformation.swift
//
//  Created by Facundo Menzella on 23/5/25.

import Foundation
@_spi(Internal) import RevenueCat

extension Array<CustomerCenterConfigData.HelpPath> {
    func relevantPaths(
        for purchaseInformation: PurchaseInformation?,
        allowMissingPurchase: Bool,
        localization: CustomerCenterConfigData.Localization = .default
    ) -> [CustomerCenterConfigData.HelpPath] {
        filter { $0.hiddenReason(for: purchaseInformation, allowMissingPurchase: allowMissingPurchase) == nil }
            .map { path in
                guard let purchaseInformation else { return path }
                return path.resubscribeVariantIfNeeded(for: purchaseInformation, localization: localization)
            }
    }
}

extension CustomerCenterConfigData.HelpPath {

    /// A nil reason means the path is available. Rendering and preview diagnostics share this decision.
    func hiddenReason(for purchase: PurchaseInformation?, allowMissingPurchase: Bool) -> String? {
        guard let purchase else {
            return type == .missingPurchase || type == .customAction || type == .customUrl
                ? nil : "No purchase selected"
        }
        if !allowMissingPurchase && type == .missingPurchase { return "Purchase already selected" }
        if purchase.ownershipType == .familyShared && type.requiresPurchaseOwnership {
            return "Family-shared purchase"
        }
        if purchase.store != .appStore && type.isAppStoreOnly { return "Requires an App Store purchase" }
        switch type {
        case .cancel:
            return cancellationHiddenReason(for: purchase)
        case .refundRequest:
            return refundHiddenReason(for: purchase)
        case .changePlans:
            return !purchase.isAppStoreRenewableSubscription || purchase.isLifetime || purchase.isExpired
                ? "Requires an active renewable subscription" : nil
        default:
            return nil
        }
    }

    private func cancellationHiddenReason(for purchase: PurchaseInformation) -> String? {
        if purchase.store != .appStore {
            return purchase.managementURL == nil ? "No management URL" : nil
        }
        if !purchase.isAppStoreRenewableSubscription { return "No renewable subscription" }
        if purchase.isExpired { return "Subscription expired" }
        return !purchase.isCancelled && purchase.renewalDate == nil ? "No renewal date" : nil
    }

    private func refundHiddenReason(for purchase: PurchaseInformation) -> String? {
        if purchase.pricePaid == .free { return "Free purchase" }
        if purchase.isTrial { return "Trial purchase" }
        return refundWindowDuration?.isWithin(purchase) == false ? "Refund window exceeded" : nil
    }

    /// Cancelling is meaningless once the customer already cancelled, so the same path becomes
    /// the way back in. The survey and the offer belong to churn, not to returning.
    func resubscribeVariantIfNeeded(
        for purchaseInformation: PurchaseInformation,
        localization: CustomerCenterConfigData.Localization
    ) -> CustomerCenterConfigData.HelpPath {
        guard self.type == .cancel,
              purchaseInformation.isCancelled,
              !purchaseInformation.isExpired else {
            return self
        }

        return CustomerCenterConfigData.HelpPath(
            id: self.id,
            title: localization[.resubscribe],
            url: self.url,
            openMethod: self.openMethod,
            type: self.type,
            detail: nil,
            refundWindowDuration: self.refundWindowDuration,
            customActionIdentifier: self.customActionIdentifier
        )
    }
}

private extension CustomerCenterConfigData.HelpPath.PathType {

    /// Whether the App Store rejects this action unless the customer owns the purchase.
    var requiresPurchaseOwnership: Bool {
        switch self {
        case .refundRequest, .changePlans:
            return true

        case .cancel, .customUrl, .customAction, .missingPurchase, .unknown:
            return false

        @unknown default:
            return false
        }
    }

    var isAppStoreOnly: Bool {
        switch self {
        case .cancel, .customUrl, .customAction, .missingPurchase:
            return false

        case .changePlans, .refundRequest, .unknown:
            return true

        @unknown default:
            return false
        }
    }
}

private extension CustomerCenterConfigData.HelpPath.RefundWindowDuration {
    func isWithin(_ purchaseInformation: PurchaseInformation) -> Bool {
        switch self {
        case .forever:
            return true

        case let .duration(duration):
            return duration.isWithin(
                from: purchaseInformation.latestPurchaseDate,
                now: purchaseInformation.customerInfoRequestedDate
            )

        @unknown default:
            return true
        }
    }
}

private extension ISODuration {
    func isWithin(from startDate: Date?, now: Date) -> Bool {
        guard let startDate else {
            return true
        }

        var dateComponents = DateComponents()
        dateComponents.year = self.years
        dateComponents.month = self.months
        dateComponents.weekOfYear = self.weeks
        dateComponents.day = self.days
        dateComponents.hour = self.hours
        dateComponents.minute = self.minutes
        dateComponents.second = self.seconds

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: dateComponents, to: startDate) ?? startDate

        return startDate < endDate && now <= endDate
    }
}
