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

// swiftlint:disable nesting

/// Information about a purchase.
struct PurchaseInformation {

    /// The title of the storekit product, if applicable.
    /// - Note: See `StoreProduct.localizedTitle` for more details.
    let title: String?

    /// The duration of the product, if applicable.
    /// - Note: See `StoreProduct.localizedDetails` for more details.
    let durationTitle: String?

    let explanation: Explanation

    /// Pricing details of the purchase.
    let price: PriceDetails

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

    let latestPurchaseDate: Date?

    /// The fetch date of this CustomerInfo. (a.k.a. CustomerInfo.requestedDate)
    let customerInfoRequestedDate: Date

    /// Indicates wheter the purchased subscripcion is cancelled
    /// - `true` if the subscription is user-cancelled
    /// - `false` if the subscription is not user-cancelled
    ///
    /// Note: `false` for non-subscriptions
    let isCancelled: Bool

    let introductoryDiscount: StoreProductDiscountType?

    let expirationDate: Date?

    let renewalDate: Date?

    init(title: String,
         durationTitle: String?,
         explanation: Explanation,
         price: PriceDetails,
         expirationOrRenewal: ExpirationOrRenewal?,
         productIdentifier: String,
         store: Store,
         isTrial: Bool,
         isLifetime: Bool,
         latestPurchaseDate: Date?,
         isCancelled: Bool = false,
         customerInfoRequestedDate: Date,
         introductoryDiscount: StoreProductDiscountType? = nil,
         expirationDate: Date? = nil,
         renewalDate: Date? = nil
    ) {
        self.title = title
        self.durationTitle = durationTitle
        self.explanation = explanation
        self.price = price
        self.expirationOrRenewal = expirationOrRenewal
        self.productIdentifier = productIdentifier
        self.store = store
        self.isLifetime = isLifetime
        self.isTrial = isTrial
        self.latestPurchaseDate = latestPurchaseDate
        self.isCancelled = isCancelled
        self.customerInfoRequestedDate = customerInfoRequestedDate
        self.introductoryDiscount = introductoryDiscount
        self.expirationDate = expirationDate
        self.renewalDate = renewalDate
    }

    // swiftlint:disable:next function_body_length
    init(entitlement: EntitlementInfo? = nil,
         storeProduct: StoreProduct? = nil,
         transaction: Transaction,
         renewalPrice: PriceDetails? = nil,
         customerInfoRequestedDate: Date,
         dateFormatter: DateFormatter = DateFormatter()) {
        dateFormatter.dateStyle = .medium

        // Title and duration from product if available
        self.title = storeProduct?.localizedTitle
        self.durationTitle = storeProduct?.subscriptionPeriod?.durationTitle
        self.customerInfoRequestedDate = customerInfoRequestedDate
        self.introductoryDiscount = storeProduct?.introductoryDiscount

        // Use entitlement data if available, otherwise derive from transaction
        if let entitlement = entitlement {
            self.explanation = entitlement.explanation
            self.expirationOrRenewal = entitlement.expirationOrRenewal(dateFormatter: dateFormatter)
            self.productIdentifier = entitlement.productIdentifier
            self.store = entitlement.store
            if let renewalPrice {
                self.price = renewalPrice
            } else {
                self.price = entitlement.priceBestEffort(product: storeProduct)
            }
            self.isLifetime = entitlement.expirationDate == nil

            self.latestPurchaseDate = entitlement.latestPurchaseDate

            self.isTrial = entitlement.periodType == .trial
            self.isCancelled = entitlement.unsubscribeDetectedAt != nil && !entitlement.willRenew
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

            if transaction.store == .promotional {
                self.price = .free
            } else {
                if let renewalPrice {
                    self.price = renewalPrice
                } else {
                    self.price = storeProduct.map { .paid($0.localizedPriceString) } ?? .unknown
                }
            }

            self.isCancelled = transaction.isCancelled
        }
    }

    struct ExpirationOrRenewal {
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
        case paid(String)
        case unknown
    }

    enum Explanation {
        case promotional
        case google
        case web
        case otherStorePurchase
        case amazon
        case earliestRenewal
        case earliestExpiration
        case expired
        case lifetime
    }
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
        customerInfoRequestedDate: Date
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
            customerInfoRequestedDate: customerInfoRequestedDate
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

        return .paid(formattedPrice)
    }
}

fileprivate extension EntitlementInfo {

    func priceBestEffort(product: StoreProduct?) -> PurchaseInformation.PriceDetails {
        if let product {
            return .paid(product.localizedPriceString)
        }
        if self.store == .promotional {
            return .free
        }
        return .unknown
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
        case .stripe, .rcBilling:
            return .web
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

fileprivate extension String {

    func isPromotionalLifetime(store: Store) -> Bool {
        return self.hasSuffix("_lifetime") && store == .promotional
    }

}

protocol Transaction {

    var productIdentifier: String { get }
    var store: Store { get }
    var type: TransactionType { get }
    var isCancelled: Bool { get }
}

enum TransactionType {

    case subscription(isActive: Bool, willRenew: Bool, expiresDate: Date?, isTrial: Bool)
    case nonSubscription
}

extension RevenueCat.SubscriptionInfo: Transaction {

    var type: TransactionType {
        .subscription(isActive: isActive,
                      willRenew: willRenew,
                      expiresDate: expiresDate,
                      isTrial: periodType == .trial)
    }

    var isCancelled: Bool {
        unsubscribeDetectedAt != nil && !willRenew
    }
}

extension NonSubscriptionTransaction: Transaction {

    var type: TransactionType {
        .nonSubscription
    }

    var isCancelled: Bool {
        false
    }
}

extension PurchaseInformation {

    var billingInformation: String {
        guard let expirationDate else {
            // non subscription
            return "-"
        }

        if let introductoryDiscount {
            if introductoryDiscount.paymentMode == .freeTrial {
                if isCancelled {
                    return "Free trial expires on \(expirationDate) without any charges"
                } else {
                    return "Free trial until \(expirationDate). \(introductoryDiscount.localizedPricePerPeriodByPaymentMode(.current)) afterwards."
                }
            }

            if isCancelled {
                return "\(introductoryDiscount.titleString), renewal off: Expires on \(expirationDate) without further charges."
            } else {
                var renewString = "renewal on: \(introductoryDiscount.localizedPricePerPeriodByPaymentMode(.current))"
                renewString += " <regular price per period> per <period> afterwards"
                return renewString
            }
        } else if isCancelled {
            switch price {
            case let .paid(priceString):
                return "\(priceString) per <period>. Next bill on \(expirationDate)"
            case .free, .unknown:
                return "Next bill on \(expirationDate)"
            }
        } else {
            switch price {
            case let .paid(priceString):
                return "\(priceString) per <period>. Expires on \(expirationDate) without further charges."
            case .free, .unknown:
                return "Next bill on \(expirationDate)"
            }
        }
    }
}

private extension StoreProductDiscountType {
    var titleString: String {
        switch paymentMode {
        case .payAsYouGo:
            return "Pay as you go"
        case .freeTrial:
            return "Free trial"
        case .payUpFront:
            return "Pay up front"
        }
    }
}
