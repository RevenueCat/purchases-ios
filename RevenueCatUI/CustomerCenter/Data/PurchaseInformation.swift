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

// swiftlint:disable file_length

/// Information about a purchase.
struct PurchaseInformation {

    /// The `localizedTitle` of the StoreKit product, if available.
    /// Otherwise, the display name configured in the RevenueCat dashboard.
    /// If neither the title or the display name are available, the product identifier will be used as a fallback.
    let title: String

    /// The duration of the product, if applicable.
    /// - Note: See `StoreProduct.localizedDetails` for more details.
    let durationTitle: String?

    /// Pricing details of the latest purchase.
    let pricePaid: PricePaid

    /// Renewal pricing details of the subscription.
    /// It can be nil if we don't have renewal information, if it's a consumable, or if it doesn't renew
    let renewalPrice: RenewalPrice?

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

    let latestPurchaseDate: Date

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

    let periodType: PeriodType

    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter

    init(title: String,
         durationTitle: String?,
         pricePaid: PricePaid,
         renewalPrice: RenewalPrice?,
         productIdentifier: String,
         store: Store,
         isLifetime: Bool,
         isTrial: Bool,
         isCancelled: Bool,
         latestPurchaseDate: Date,
         customerInfoRequestedDate: Date,
         dateFormatter: DateFormatter = Self.defaultDateFormatter,
         numberFormatter: NumberFormatter = Self.defaultNumberFormatter,
         managementURL: URL?,
         expirationDate: Date? = nil,
         renewalDate: Date? = nil,
         periodType: PeriodType = .normal
    ) {
        self.title = title
        self.durationTitle = durationTitle
        self.pricePaid = pricePaid
        self.renewalPrice = renewalPrice
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
        self.periodType = periodType
        self.numberFormatter = numberFormatter
    }

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
            self.productIdentifier = entitlement.productIdentifier
            self.store = entitlement.store
            self.isLifetime = entitlement.expirationDate == nil
            self.isTrial = entitlement.periodType == .trial
            self.isCancelled = entitlement.isCancelled
            // entitlement.latestPurchaseDate is optional, but it shouldn't.
            // date will be the one from the entitlement
            self.latestPurchaseDate = entitlement.latestPurchaseDate ?? transaction.purchaseDate
            self.expirationDate = entitlement.expirationDate
            self.renewalDate = entitlement.willRenew ? entitlement.expirationDate : nil
            self.periodType = entitlement.periodType
        } else {
            switch transaction.type {
            case let .subscription(_, willRenew, expiresDate, isTrial):
                self.isLifetime = false
                self.isTrial = isTrial
                self.expirationDate = expiresDate
                self.renewalDate = willRenew ? expiresDate : nil

            case .nonSubscription:
                self.isLifetime = true
                self.isTrial = false
                self.renewalDate = nil
                self.expirationDate = nil
            }

            self.latestPurchaseDate = transaction.purchaseDate
            self.productIdentifier = transaction.productIdentifier
            self.store = transaction.store
            self.isCancelled = transaction.isCancelled
            self.periodType = transaction.periodType
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

    enum PricePaid: Equatable, Hashable {
        case free
        case nonFree(String)
        case unknown
    }

    enum RenewalPrice: Equatable, Hashable {
        case free
        case nonFree(String)
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
}

private extension String {

    func isPromotionalLifetime(store: Store) -> Bool {
        return self.hasSuffix("_lifetime") && store == .promotional
    }
}

extension PurchaseInformation {

    func pricePaidString(localizations: CustomerCenterConfigData.Localization) -> String? {
        switch pricePaid {
        case .free:
            return localizations[.free]
        case let .nonFree(priceString):
            return priceString
        case .unknown:
            return nil
        }
    }

    func priceRenewalString(
        date: Date,
        localizations: CustomerCenterConfigData.Localization
    ) -> String? {
        guard let renewalPrice else {
            return nil
        }

        switch renewalPrice {
        case .free:
            return localizations[.renewsOnDate]
                .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: date))
        case .nonFree(let priceString):
            return localizations[.renewsOnDateForPrice]
                .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: date))
                .replacingOccurrences(of: "{{ price }}", with: priceString)
        }
    }

    func expirationString(
        localizations: CustomerCenterConfigData.Localization
    ) -> String? {
        guard let expirationDate else {
            return nil
        }

        return localizations[.expiresOnDateWithoutChanges]
            .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: expirationDate))
    }
}
// swiftlint:enable file_length
