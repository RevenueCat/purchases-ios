//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionInformation.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import RevenueCat
import StoreKit

// swiftlint:disable nesting file_length

/// Information about a purchase.
struct PurchaseInformation {

    /// The `localizedTitle` of the StoreKit product, if available.
    /// Otherwise, the display name configured in the RevenueCat dashboard.
    /// If neither the title or the display name are available, the product identifier will be used as a fallback.
    let title: String

    /// The duration of the product, if applicable.
    /// - Note: See `StoreProduct.localizedDetails` for more details.
    let durationTitle: String?

    let explanation: Explanation

    /// Pricing details of the latest purchase.
    let pricePaid: PricePaid

    /// Renewal pricing details of the subscription.
    /// It can be nil if we don't have renewal information, if it's a consumable, or if it doesn't renew
    let renewalPrice: RenewalPrice?

    /// Subscription expiration or renewal details, if applicable.
    ///
    /// Note: Deprecated, soon to be deleted
    let expirationOrRenewal: ExpirationOrRenewal?

    /// The unique product identifier for the purchase.
    let productIdentifier: String

    /// The store from which the purchase was made (e.g., App Store, Play Store).
    let store: Store

    /// Indicates whether the purchase grants lifetime access.
    /// - `true` for non-subscription purchases.
    /// - `false` for subscriptions, even if the expiration date is set far in the future.
    let isLifetime: Bool

    /// Indicates whether the purchase is under a trial period.
    /// - `true` for purchases within the trial period.
    /// - `false` for purchases outside the trial period.
    let isTrial: Bool

    /// Indicates whether the purchased subscription is cancelled
    /// - `true` if the subscription is user-cancelled
    /// - `false` if the subscription is not user-cancelled
    ///
    /// Note: `false` for non-subscriptions
    let isCancelled: Bool

    let latestPurchaseDate: Date?

    /// The fetch date of this CustomerInfo. (a.k.a. CustomerInfo.requestedDate)
    let customerInfoRequestedDate: Date

    /// Indicates the date when the subscription expires.
    ///
    /// Note: `nil` for non-subscriptions, and for renewing subscriptions
    let expirationDate: Date?

    /// Indicates the date when the subscription renews.
    ///
    /// Note: `nil` for non-subscriptions, and for expiring subscriptions
     let renewalDate: Date?

    /// Product specific management URL
    let managementURL: URL?

    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter

    init(title: String,
         durationTitle: String?,
         explanation: Explanation,
         pricePaid: PricePaid,
         renewalPrice: RenewalPrice?,
         expirationOrRenewal: ExpirationOrRenewal?,
         productIdentifier: String,
         store: Store,
         isLifetime: Bool,
         isTrial: Bool,
         isCancelled: Bool,
         latestPurchaseDate: Date?,
         customerInfoRequestedDate: Date,
         dateFormatter: DateFormatter = Self.defaultDateFormatter,
         numberFormatter: NumberFormatter = Self.defaultNumberFormatter,
         managementURL: URL?,
         expirationDate: Date? = nil,
         renewalDate: Date? = nil
    ) {
        self.title = title
        self.durationTitle = durationTitle
        self.explanation = explanation
        self.pricePaid = pricePaid
        self.renewalPrice = renewalPrice
        self.expirationOrRenewal = expirationOrRenewal
        self.productIdentifier = productIdentifier
        self.store = store
        self.isLifetime = isLifetime
        self.isTrial = isTrial
        self.isCancelled = isCancelled
        self.latestPurchaseDate = latestPurchaseDate
        self.customerInfoRequestedDate = customerInfoRequestedDate
        self.managementURL = managementURL
        self.expirationDate = expirationDate
        self.renewalDate = renewalDate
        self.dateFormatter = dateFormatter
        self.numberFormatter = numberFormatter
    }

    // swiftlint:disable:next function_body_length
    init(entitlement: EntitlementInfo? = nil,
         subscribedProduct: StoreProduct? = nil,
         transaction: Transaction,
         renewalPrice: RenewalPrice? = nil,
         customerInfoRequestedDate: Date,
         dateFormatter: DateFormatter = Self.defaultDateFormatter,
         numberFormatter: NumberFormatter = Self.defaultNumberFormatter,
         managementURL: URL?
    ) {
        self.dateFormatter = dateFormatter
        self.numberFormatter = numberFormatter

        // Title and duration from product if available
        self.title = subscribedProduct?.localizedTitle ?? transaction.productIdentifier
        self.durationTitle = subscribedProduct?.subscriptionPeriod?.durationTitle

        self.customerInfoRequestedDate = customerInfoRequestedDate
        self.managementURL = managementURL

        // Use entitlement data if available, otherwise derive from transaction
        if let entitlement = entitlement {
            self.explanation = entitlement.explanation
            self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
            self.productIdentifier = entitlement.productIdentifier
            self.store = entitlement.store
            self.isLifetime = entitlement.expirationDate == nil
            self.isTrial = entitlement.periodType == .trial
            self.isCancelled = entitlement.isCancelled
            self.latestPurchaseDate = entitlement.latestPurchaseDate
            self.expirationDate = entitlement.expirationDate
            self.renewalDate = entitlement.willRenew ? entitlement.expirationDate : nil
        } else {
            switch transaction.type {
            case let .subscription(isActive, willRenew, expiresDate, isTrial):
                self.explanation = expiresDate != nil
                ? (isActive ? (willRenew ? .earliestRenewal : .earliestExpiration) : .expired)
                : .lifetime
                self.expirationOrRenewal = expiresDate.map { date in
                    let dateString = dateFormatter.string(from: date)
                    let label: ExpirationOrRenewal.Label = isActive
                    ? (willRenew ? .nextBillingDate : .expires)
                    : .expired
                    return ExpirationOrRenewal(label: label, date: .date(dateString))
                }
                self.isLifetime = false
                self.isTrial = isTrial
                self.latestPurchaseDate = (transaction as? RevenueCat.SubscriptionInfo)?.purchaseDate
                self.expirationDate = expiresDate
                self.renewalDate = willRenew ? expiresDate : nil

            case .nonSubscription:
                self.explanation = .lifetime
                self.expirationOrRenewal = nil
                self.isLifetime = true
                self.isTrial = false
                self.latestPurchaseDate = (transaction as? NonSubscriptionTransaction)?.purchaseDate
                self.renewalDate = nil
                self.expirationDate = nil
            }

            self.productIdentifier = transaction.productIdentifier
            self.store = transaction.store
            self.isCancelled = transaction.isCancelled
        }

        if self.expirationDate == nil {
            self.renewalPrice = nil
        } else if let renewalPrice {
            self.renewalPrice = renewalPrice
        } else {
            self.renewalPrice = transaction.determineRenewalPrice(numberFormatter: numberFormatter)
        }

        self.pricePaid = transaction.paidPrice(numberFormatter: numberFormatter)
    }

    struct ExpirationOrRenewal: Equatable {
        let label: Label
        let date: Date

        enum Label {
            case nextBillingDate
            case expires
            case expired
        }

        enum Date: Equatable {
            case never
            case date(String)
        }
    }

    enum PricePaid: Equatable, Hashable {
        case free
        case nonFree(String)
        case unknown
    }

    enum RenewalPrice: Equatable, Hashable {
        case free
        case nonFree(String)
    }

    enum Explanation {
        case promotional
        case google
        case externalWeb
        case rcWebBilling
        case otherStorePurchase
        case amazon
        case earliestRenewal
        case earliestExpiration
        case expired
        case lifetime
    }

    static let defaultDateFormatter: DateFormatter = {
         let dateFormatter = DateFormatter()
         dateFormatter.dateStyle = .medium
         return dateFormatter
     }()

    static let defaultNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
}

extension PurchaseInformation: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(durationTitle)
        hasher.combine(explanation)
        hasher.combine(pricePaid)
        hasher.combine(renewalPrice)
        hasher.combine(renewalDate)
        hasher.combine(productIdentifier)
        hasher.combine(store)
        hasher.combine(isLifetime)
        hasher.combine(isCancelled)
        hasher.combine(latestPurchaseDate)
        hasher.combine(customerInfoRequestedDate)
        hasher.combine(expirationDate)
        hasher.combine(renewalDate)
        hasher.combine(managementURL)
    }
 }

extension PurchaseInformation: Identifiable {

    var id: Self { self }
}

// swiftlint:enable nesting

extension PurchaseInformation {

    /// Provides detailed information about a user's purchase, including renewal price.
    ///
    /// This function fetches the renewal price details for the given product asynchronously from
    /// StoreKit 2 and constructs a `PurchaseInformation` object with the provided
    /// transaction, entitlement, and subscribed product details.
    ///
    /// - Parameters:
    ///   - entitlement: Optional entitlement information associated with the purchase.
    ///   - subscribedProduct: The product the user has subscribed to, represented as a `StoreProduct`.
    ///   - transaction: The transaction information for the purchase.
    /// - Returns: A `PurchaseInformation` object containing the purchase details, including the renewal price.
    ///
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    static func purchaseInformationUsingRenewalInfo(
        entitlement: EntitlementInfo? = nil,
        subscribedProduct: StoreProduct,
        transaction: Transaction,
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType,
        customerInfoRequestedDate: Date,
        dateFormatter: DateFormatter = Self.defaultDateFormatter,
        numberFormatter: NumberFormatter = Self.defaultNumberFormatter,
        managementURL: URL?
    ) async -> PurchaseInformation {
        let renewalPriceDetails = await Self.extractPriceDetailsFromRenewalInfo(
            forProduct: subscribedProduct,
            customerCenterStoreKitUtilities: customerCenterStoreKitUtilities,
            numberFormatter: numberFormatter
        )
        return PurchaseInformation(
            entitlement: entitlement,
            subscribedProduct: subscribedProduct,
            transaction: transaction,
            renewalPrice: renewalPriceDetails,
            customerInfoRequestedDate: customerInfoRequestedDate,
            dateFormatter: dateFormatter,
            numberFormatter: numberFormatter,
            managementURL: managementURL
        )
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    private static func extractPriceDetailsFromRenewalInfo(
        forProduct product: StoreProduct,
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType,
        numberFormatter: NumberFormatter
    ) async -> RenewalPrice? {
        guard let renewalPriceDetails = await customerCenterStoreKitUtilities.renewalPriceFromRenewalInfo(
            for: product
        ) else {
            return nil
        }

        numberFormatter.currencyCode = renewalPriceDetails.currencyCode

        guard let formattedPrice =
                numberFormatter.string(from: renewalPriceDetails.price as NSNumber) else {
            return nil
        }

        return .nonFree(formattedPrice)
    }
}

private extension Transaction {

    func determineRenewalPrice(numberFormatter: NumberFormatter) -> PurchaseInformation.RenewalPrice? {
        if self.productIdentifier.isPromotionalLifetime(store: self.store) {
            return nil
        }

        guard self.store == .rcBilling else {
            // RCBilling does not support product price changes yet
            // So it's the only store we can infer the renewal price from
            // latest price paid
            return nil
        }

        if unableToInferRenewalPrice {
            return nil
        }

        guard let price = self.price, price.amount != 0 else {
            return nil
        }

        numberFormatter.currencyCode = price.currency

        guard let formattedPrice = numberFormatter.string(from: price.amount as NSNumber) else { return nil }

        return .nonFree(formattedPrice)
    }

    func paidPrice(numberFormatter: NumberFormatter) -> PurchaseInformation.PricePaid {
        if self.store == .promotional || self.price?.amount == 0 {
            return .free
        }

        guard let price = self.price,
              price.amount != 0 else {
            return .unknown
        }

        numberFormatter.currencyCode = price.currency

        guard let formattedPrice = numberFormatter.string(from: price.amount as NSNumber) else { return .unknown }

        return .nonFree(formattedPrice)
    }

    var unableToInferRenewalPrice: Bool {
        if case let .subscription(_, willRenew, _, isTrial) = self.type {
            return !willRenew || isTrial
        }

        // For non-subscriptions, always return true
        return true
    }
}

private extension EntitlementInfo {

    var isCancelled: Bool {
        unsubscribeDetectedAt != nil && !willRenew
    }

    func durationTitleBestEffort(productIdentifier: String) -> String? {
        switch self.store {
        case .promotional:
            if productIdentifier.isPromotionalLifetime(store: store) {
                return "Lifetime"
            }
        case .appStore, .macAppStore, .playStore, .stripe, .unknownStore, .amazon, .rcBilling, .external:
            return nil
        @unknown default:
            return nil
        }
        return nil
    }

    func expirationOrRenewal(dateFormatter: DateFormatter) -> PurchaseInformation.ExpirationOrRenewal? {
        guard let date = expirationDateBestEffort(dateFormatter: dateFormatter) else {
            return nil
        }
        let label: PurchaseInformation.ExpirationOrRenewal.Label =
        self.isActive ? (
            self.willRenew ? .nextBillingDate : .expires
        ) : .expired
        return PurchaseInformation.ExpirationOrRenewal(label: label, date: date)

    }

    var explanation: PurchaseInformation.Explanation {
        switch self.store {
        case .appStore, .macAppStore:
            if self.expirationDate != nil {
                if self.isActive {
                    return self.willRenew ? .earliestRenewal : .earliestExpiration
                } else {
                    return .expired
                }
            } else {
                return .lifetime
            }
        case .promotional:
            return .promotional
        case .playStore:
            return .google
        case .rcBilling:
            return .rcWebBilling
        case .stripe:
            return .externalWeb
        case .external, .unknownStore:
            return .otherStorePurchase
        case .amazon:
            return .amazon
        }
    }

    private func expirationDateBestEffort(
        dateFormatter: DateFormatter
    ) -> PurchaseInformation.ExpirationOrRenewal.Date? {
        if self.expirationDate == nil {
            return .never
        }
        switch self.store {
        case .promotional:
            if self.productIdentifier.isPromotionalLifetime(store: self.store) {
                return .never
            }
            if let date = self.expirationDate.map({ dateFormatter.string(from: $0) }) {
                return .date(date)
            }
            return nil
        case .appStore, .macAppStore, .playStore, .stripe, .unknownStore, .amazon, .rcBilling, .external:
            if let date = self.expirationDate.map({ dateFormatter.string(from: $0) }) {
                return .date(date)
            }
            return nil
        @unknown default:
            return nil
        }
    }

}

private extension String {

    func isPromotionalLifetime(store: Store) -> Bool {
        return self.hasSuffix("_lifetime") && store == .promotional
    }
}
// swiftlint:enable file_length
