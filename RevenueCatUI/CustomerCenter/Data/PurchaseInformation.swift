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

// swiftlint:disable nesting file_length

/// Information about a purchase.
struct PurchaseInformation {

    /// The title of the storekit product, if applicable.
    /// - Note: See `StoreProduct.localizedTitle` for more details.
    let title: String

    /// The duration of the product, if applicable.
    /// - Note: See `StoreProduct.localizedDetails` for more details.
    let durationTitle: String?

    let explanation: Explanation

    /// Pricing details of the latest purchase.
    let pricePaid: PriceDetails

    /// Renewal pricing details of the subscription.
    let renewalPrice: PriceDetails?

    /// Subscription expiration or renewal details, if applicable.
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

    /// Indicates wheter the purchased subscripcion is cancelled
    /// - `true` if the subscription is user-cancelled
    /// - `false` if the subscription is not user-cancelled
    ///
    /// Note: `false` for non-subscriptions
    let isCancelled: Bool

    let latestPurchaseDate: Date?

    /// The fetch date of this CustomerInfo. (a.k.a. CustomerInfo.requestedDate)
    let customerInfoRequestedDate: Date

    let introductoryDiscount: StoreProductDiscountType?

    let expirationDate: Date?

    let renewalDate: Date?

    private let dateFormatter: DateFormatter

    let managePurchaseURL: URL?

    init(title: String,
         durationTitle: String?,
         explanation: Explanation,
         pricePaid: PriceDetails,
         renewalPrice: PriceDetails?,
         expirationOrRenewal: ExpirationOrRenewal?,
         productIdentifier: String,
         store: Store,
         isLifetime: Bool,
         isTrial: Bool,
         latestPurchaseDate: Date?,
         customerInfoRequestedDate: Date,
         isCancelled: Bool = false,
         introductoryDiscount: StoreProductDiscountType? = nil,
         expirationDate: Date? = nil,
         renewalDate: Date? = nil,
         managePurchaseURL: URL?
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
        self.introductoryDiscount = introductoryDiscount
        self.expirationDate = expirationDate
        self.renewalDate = renewalDate
        self.dateFormatter = Self.defaultDateFormatter
        self.managePurchaseURL = managePurchaseURL
    }

    // swiftlint:disable:next function_body_length
    init(entitlement: EntitlementInfo? = nil,
         storeProduct: StoreProduct? = nil,
         transaction: Transaction,
         renewalPrice: PriceDetails? = nil,
         customerInfoRequestedDate: Date,
         managePurchaseURL: URL?,
         dateFormatter: DateFormatter = Self.defaultDateFormatter
    ) {
        dateFormatter.dateStyle = .medium

        // Title and duration from product if available
        self.title = storeProduct?.localizedTitle ?? transaction.displayName ?? transaction.productIdentifier
        self.durationTitle = storeProduct?.subscriptionPeriod?.durationTitle
        self.customerInfoRequestedDate = customerInfoRequestedDate
        self.introductoryDiscount = storeProduct?.introductoryDiscount
        self.managePurchaseURL = managePurchaseURL

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

                self.expirationDate = expiresDate
                self.renewalDate = willRenew ? expiresDate : nil
                self.latestPurchaseDate = (transaction as? RevenueCat.SubscriptionInfo)?.purchaseDate

            case .nonSubscription:
                self.explanation = .lifetime
                self.expirationOrRenewal = nil
                self.isLifetime = true
                self.renewalDate = nil
                self.expirationDate = nil
                self.isTrial = false
                self.latestPurchaseDate = (transaction as? NonSubscriptionTransaction)?.purchaseDate
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
            self.renewalPrice = transaction.determineRenewalPrice()
        }

        self.pricePaid = transaction.paidPrice()

        self.dateFormatter = dateFormatter
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

    enum PriceDetails: Equatable {
        case free
        case nonFree(String)
        case unknown
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

    private static let defaultDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
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
        storeProduct: StoreProduct,
        transaction: Transaction,
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType,
        customerInfoRequestedDate: Date,
        managePurchaseURL: URL?
    ) async -> PurchaseInformation {
        let renewalPriceDetails = await Self.extractPriceDetailsFromRenewalInfo(
            forProduct: storeProduct,
            customerCenterStoreKitUtilities: customerCenterStoreKitUtilities
        )
        return PurchaseInformation(
            entitlement: entitlement,
            storeProduct: storeProduct,
            transaction: transaction,
            renewalPrice: renewalPriceDetails,
            customerInfoRequestedDate: customerInfoRequestedDate,
            managePurchaseURL: managePurchaseURL
        )
    }

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
    private static func extractPriceDetailsFromRenewalInfo(
        forProduct product: StoreProduct,
        customerCenterStoreKitUtilities: CustomerCenterStoreKitUtilitiesType
    ) async -> PriceDetails? {
        guard let renewalPriceDetails = await customerCenterStoreKitUtilities.renewalPriceFromRenewalInfo(
            for: product
        ) else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = renewalPriceDetails.currencyCode

        guard let formattedPrice = formatter.string(from: renewalPriceDetails.price as NSNumber) else { return nil }

        return .nonFree(formattedPrice)
    }
}

extension PurchaseInformation: Identifiable {

    var id: String {
        let formatter = ISO8601DateFormatter()
        let purchaseDateString = latestPurchaseDate.map { formatter.string(from: $0) }
            ?? formatter.string(from: Date())
        return "\(productIdentifier)_\(purchaseDateString)"
    }
}

private extension Transaction {

    func determineRenewalPrice() -> PurchaseInformation.PriceDetails {
        if self.productIdentifier.isPromotionalLifetime(store: self.store) {
            return .free
        }

        guard let price = self.price,
              price.amount != 0 else {
            // If it was a trial we can't infer the renewal price
            return .unknown
        }

        guard self.store == .rcBilling else {
            // RCBilling does not support product price changes yet
            // So it's the only store we can infer the renewal price from
            // latest price paid
            return .unknown
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = price.currency

        guard let formattedPrice = formatter.string(from: price.amount as NSNumber) else { return .unknown }

        return .nonFree(formattedPrice)
    }

    func paidPrice() -> PurchaseInformation.PriceDetails {
        if self.store == .promotional || self.price?.amount == 0 {
            return .free
        }

        guard let price = self.price,
              price.amount != 0 else {
            return .unknown
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = price.currency

        guard let formattedPrice = formatter.string(from: price.amount as NSNumber) else { return .unknown }

        return .nonFree(formattedPrice)
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

extension PurchaseInformation {

    func billingInformation(localizations: CustomerCenterConfigData.Localization) -> String {
        guard let expirationDate else {
            // non subscription
            return localizations[.pricePaid]
                .replacingOccurrences(of: "{{ price }}",
                                      with: pricePaid.billingInformation(localizations: localizations))
        }

        if let introductoryDiscount {
            if isCancelled {
                var renewString = "\(introductoryDiscount.localizedPricePerPeriodByPaymentMode(.current))."
                renewString += localizations[.expiresOnDateWithoutChanges]
                    .replacingOccurrences(of: "{{ date }}",
                                          with: dateFormatter.string(from: expirationDate))
                return renewString
            }

            if introductoryDiscount.paymentMode == .freeTrial {
                return localizations[.freeTrialUntilDate]
                    .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: expirationDate))
                    .replacingOccurrences(of: "{{ price }}", with: priceAfterDiscount(localizations: localizations))
            } else {
                let introPrice = introductoryDiscount.localizedPricePerPeriodByPaymentMode(.current)
                if let renewalPrice = renewalPrice {
                    return "\(introPrice). \(priceAfterDiscount(price: renewalPrice, localizations: localizations))"
                } else {
                    return "\(introPrice)."
                }
            }
        } else if isCancelled {
            return localizations[.expiresOnDateWithoutChanges]
                .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: expirationDate))
        } else {
            switch renewalPrice {
            case let .nonFree(priceString):
                return localizations[.renewsOnDateForPrice]
                    .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: expirationDate))
                    .replacingOccurrences(of: "{{ price }}", with: priceString)
            case .free, .unknown, .none:
                return localizations[.renewsOnDate]
                    .replacingOccurrences(of: "{{ date }}", with: dateFormatter.string(from: expirationDate))
            }
        }
    }

    func priceAfterDiscount(price: PurchaseInformation.PriceDetails,
                            localizations: CustomerCenterConfigData.Localization) -> String {
        return localizations[.priceAfterwards]
            .replacingOccurrences(of: "{{ price }}",
                                  with: price.billingInformation(localizations: localizations))
    }
}

private extension PurchaseInformation.PriceDetails {
    func billingInformation(localizations: CustomerCenterConfigData.Localization) -> String {
        switch self {
        case .free:
            return localizations[.free]
        case .nonFree(let priceString):
            return priceString
        case .unknown:
            return "Unknown"
        }
    }

    var isCancelled: Bool {
        false
    }
}
