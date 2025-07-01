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
@_spi(Internal) import RevenueCat
import StoreKit

// swiftlint:disable file_length

/// Information about a purchase.
struct PurchaseInformation {

    /// The `localizedTitle` of the StoreKit product, if available.
    /// Otherwise, the display name configured in the RevenueCat dashboard.
    /// If neither the title or the display name are available, the product identifier will be used as a fallback.
    let title: String

    /// Pricing details of the latest purchase.
    let pricePaid: PricePaid

    /// Renewal pricing details of the subscription.
    /// It can be nil if we don't have renewal information, if it's a consumable, or if it doesn't renew
    let renewalPrice: RenewalPrice?

    /// The unique product identifier for the purchase.
    let productIdentifier: String

    /// The store from which the purchase was made (e.g., App Store, Play Store).
    let store: Store

    /// Indicates whether the purchase is a subscription or not.
    let isSubscription: Bool

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

    /// Indicates whether the purchase is a sandbox one
    let isSandbox: Bool

    let latestPurchaseDate: Date

    /// Date when this subscription first started.
    ///
    /// Note: This property does not update with renewals, nor for product changes within a subscription group or
    /// resubscriptions by lapsed subscribers. `nil` for non-subscriptions
    let originalPurchaseDate: Date?

    /// Indicates whether the purchased subscription is expired
    ///
    /// Note: `false` for non-subscriptions
    let isExpired: Bool

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

    /// The date an unsubscribe was detected.
    ///
    /// Note: `nil` for non-subscriptions, and for expiring subscriptions
    let unsubscribeDetectedAt: Date?

    /// Date when RevenueCat detected any billing issues with this subscription.
    ///
    /// Note: `nil` for non-subscriptions, and for expiring subscriptions
    let billingIssuesDetectedAt: Date?

    /// Date when any grace period for this subscription expires/expired.
    /// nil if the customer has never been in a grace period.
    ///
    /// Note: `nil` for non-subscriptions, and for expiring subscriptions
    let gracePeriodExpiresDate: Date?

    /// Date when RevenueCat detected a refund of this subscription.
    ///
    /// Note: `nil` for non-subscriptions
    let refundedAtDate: Date?

    /// Product specific management URL
    let managementURL: URL?

    let periodType: PeriodType

    let ownershipType: PurchaseOwnershipType?

    let subscriptionGroupID: String?

    /// The unique identifier for the transaction created by RevenueCat.
    let transactionIdentifier: String?

    /// The unique identifier for the transaction created by the Store.
    let storeTransactionIdentifier: String?

    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter

    init(title: String,
         pricePaid: PricePaid,
         renewalPrice: RenewalPrice?,
         productIdentifier: String,
         store: Store,
         isSubscription: Bool,
         isTrial: Bool,
         isCancelled: Bool,
         isExpired: Bool,
         isSandbox: Bool,
         latestPurchaseDate: Date,
         originalPurchaseDate: Date?,
         customerInfoRequestedDate: Date,
         dateFormatter: DateFormatter = Self.defaultDateFormatter,
         numberFormatter: NumberFormatter = Self.defaultNumberFormatter,
         managementURL: URL?,
         expirationDate: Date? = nil,
         renewalDate: Date? = nil,
         periodType: PeriodType = .normal,
         ownershipType: PurchaseOwnershipType? = nil,
         subscriptionGroupID: String? = nil,
         unsubscribeDetectedAt: Date? = nil,
         billingIssuesDetectedAt: Date? = nil,
         gracePeriodExpiresDate: Date? = nil,
         refundedAtDate: Date? = nil,
         transactionIdentifier: String? = nil,
         storeTransactionIdentifier: String? = nil
    ) {
        self.title = title
        self.pricePaid = pricePaid
        self.renewalPrice = renewalPrice
        self.productIdentifier = productIdentifier
        self.store = store
        self.isSubscription = isSubscription
        self.isTrial = isTrial
        self.isCancelled = isCancelled
        self.isSandbox = isSandbox
        self.isExpired = isExpired
        self.latestPurchaseDate = latestPurchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.customerInfoRequestedDate = customerInfoRequestedDate
        self.managementURL = managementURL
        self.expirationDate = expirationDate
        self.renewalDate = renewalDate
        self.dateFormatter = dateFormatter
        self.periodType = periodType
        self.numberFormatter = numberFormatter
        self.ownershipType = ownershipType
        self.subscriptionGroupID = subscriptionGroupID
        self.unsubscribeDetectedAt = unsubscribeDetectedAt
        self.billingIssuesDetectedAt = billingIssuesDetectedAt
        self.gracePeriodExpiresDate = gracePeriodExpiresDate
        self.refundedAtDate = refundedAtDate
        self.transactionIdentifier = transactionIdentifier
        self.storeTransactionIdentifier = storeTransactionIdentifier
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
        if transaction.store == .promotional {
            self.title = entitlement?.identifier ?? transaction.productIdentifier
        } else {
            self.title = subscribedProduct?.localizedTitle ?? transaction.productIdentifier
        }
        self.subscriptionGroupID = subscribedProduct?.subscriptionGroupIdentifier

        self.customerInfoRequestedDate = customerInfoRequestedDate
        self.managementURL = managementURL
        self.isSubscription = transaction.isSubscrition && transaction.store != .promotional

        // Use entitlement data if available, otherwise derive from transaction
        if let entitlement = entitlement {
            self.productIdentifier = entitlement.productIdentifier
            self.store = entitlement.store
            self.isTrial = entitlement.periodType == .trial
            self.isCancelled = entitlement.isCancelled

            // entitlement.latestPurchaseDate is optional, but it shouldn't.
            // date will be the one from the entitlement
            self.latestPurchaseDate = entitlement.latestPurchaseDate ?? transaction.purchaseDate
            self.expirationDate = entitlement.expirationDate
            self.renewalDate = entitlement.willRenew ? entitlement.expirationDate : nil
            self.periodType = entitlement.periodType
            self.ownershipType = entitlement.ownershipType
            self.isExpired = !entitlement.isActive
            self.unsubscribeDetectedAt = entitlement.unsubscribeDetectedAt
            self.billingIssuesDetectedAt = entitlement.billingIssueDetectedAt
            self.gracePeriodExpiresDate = nil
            self.refundedAtDate = nil
            self.transactionIdentifier = nil
            self.storeTransactionIdentifier = nil
            self.isSandbox = entitlement.isSandbox
            self.originalPurchaseDate = entitlement.originalPurchaseDate
        } else {
            switch transaction.type {
            case let .subscription(isActive, willRenew, expiresDate, isTrial, ownershipType):
                self.isTrial = isTrial
                self.expirationDate = expiresDate
                self.renewalDate = willRenew ? expiresDate : nil
                self.ownershipType = ownershipType
                self.isExpired = !isActive

            case .nonSubscription:
                self.isTrial = false
                self.isExpired = false
                self.renewalDate = nil
                self.expirationDate = nil
                self.ownershipType = nil
            }

            self.latestPurchaseDate = transaction.purchaseDate
            self.productIdentifier = transaction.productIdentifier
            self.store = transaction.store
            self.isCancelled = transaction.isCancelled
            self.periodType = transaction.periodType
            self.unsubscribeDetectedAt = transaction.unsubscribeDetectedAt
            self.billingIssuesDetectedAt = transaction.billingIssuesDetectedAt
            self.gracePeriodExpiresDate = transaction.gracePeriodExpiresDate
            self.refundedAtDate = transaction.refundedAtDate
            self.transactionIdentifier = transaction.identifier
            self.storeTransactionIdentifier = transaction.storeIdentifier
            self.isSandbox = transaction.isSandbox
            self.originalPurchaseDate = transaction.originalPurchaseDate
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
        hasher.combine(pricePaid)
        hasher.combine(renewalPrice)
        hasher.combine(renewalDate)
        hasher.combine(productIdentifier)
        hasher.combine(store)
        hasher.combine(isSubscription)
        hasher.combine(isCancelled)
        hasher.combine(latestPurchaseDate)
        hasher.combine(customerInfoRequestedDate)
        hasher.combine(expirationDate)
        hasher.combine(renewalDate)
        hasher.combine(managementURL)
        hasher.combine(unsubscribeDetectedAt)
        hasher.combine(billingIssuesDetectedAt)
        hasher.combine(gracePeriodExpiresDate)
        hasher.combine(refundedAtDate)
        hasher.combine(transactionIdentifier)
        hasher.combine(storeTransactionIdentifier)
        hasher.combine(ownershipType)
        hasher.combine(periodType)
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
        if self.productIdentifier.isPromotionalLifetime(store: self.store),
           self.productIdentifier.isPromotional(store: self.store) {
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

        guard let price = self.price else {
            return nil
        }

        if price.amount.isZero {
            return .free
        }

        numberFormatter.currencyCode = price.currency

        guard let formattedPrice = numberFormatter.string(from: price.amount as NSNumber) else { return nil }

        return .nonFree(formattedPrice)
    }

    func paidPrice(numberFormatter: NumberFormatter) -> PurchaseInformation.PricePaid {
        if self.store == .promotional || self.price?.amount.isZero == true {
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
        if case let .subscription(_, willRenew, _, isTrial, _) = self.type {
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
}

private extension String {

    func isPromotionalLifetime(store: Store) -> Bool {
        return self.hasSuffix("_lifetime") && store == .promotional
    }

    func isPromotional(store: Store) -> Bool {
        return self.hasPrefix("rc_promo") && store == .promotional
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
        localizations: CustomerCenterConfigData.Localization
    ) -> String? {
        guard let renewalPrice, let renewalDate else {
            return nil
        }

        switch renewalPrice {
        case .free:
            return localizations[.renewsOnDateForPrice]
                .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: renewalDate))
                .replacingOccurrences(of: "{{ price }}", with: localizations[.free].lowercased())
        case .nonFree(let priceString):
            return localizations[.renewsOnDateForPrice]
                .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: renewalDate))
                .replacingOccurrences(of: "{{ price }}", with: priceString)
        }
    }

    func expirationString(
        localizations: CustomerCenterConfigData.Localization
    ) -> String? {
        guard let expirationDate else {
            return nil
        }

        var string = localizations[.expiresOnDateWithoutChanges]
        if isExpired {
            string = localizations[.purchaseInfoExpiredOnDate]
        }

        return string
            .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: expirationDate))
    }
}

extension PurchaseInformation {

    var isLifetimeSubscription: Bool {
        expirationDate == nil && isSubscription
    }

    var storeLocalizationKey: CCLocalizedString {
        switch store {
        case .appStore: return .storeAppStore
        case .macAppStore: return .storeMacAppStore
        case .playStore: return .storePlayStore
        case .promotional: return .cardStorePromotional
        case .amazon: return .storeAmazon
        case .unknownStore: return .storeUnknownStore
        case .paddle, .stripe, .rcBilling, .external:
            return .storeWeb
        }
    }
}
// swiftlint:enable file_length
