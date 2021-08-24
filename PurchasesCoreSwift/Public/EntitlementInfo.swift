//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementInfo.swift
//
//  Created by Joshua Liebowitz on 6/25/21.
//

import Foundation

/**
 Enum of supported stores
 */
@objc(RCStore) public enum Store: Int {
    /// For entitlements granted via Apple App Store.
    @objc(RCAppStore) case appStore = 0
    /// For entitlements granted via Apple Mac App Store.
    @objc(RCMacAppStore) case macAppStore = 1
    /// For entitlements granted via Google Play Store.
    @objc(RCPlayStore) case playStore = 2
    /// For entitlements granted via Stripe.
    @objc(RCStripe) case stripe = 3
    /// For entitlements granted via a promo in RevenueCat.
    @objc(RCPromotional) case promotional = 4
    /// For entitlements granted via an unknown store.
    @objc(RCUnknownStore) case unknownStore = 5
}

/**
 Enum of supported period types for an entitlement.
 */
@objc(RCPeriodType) public enum PeriodType: Int {
    /// If the entitlement is not under an introductory or trial period.
    @objc(RCNormal) case normal = 0
    /// If the entitlement is under a introductory price period.
    @objc(RCIntro) case intro = 1
    /// If the entitlement is under a trial period.
    @objc(RCTrial) case trial = 2
}

@objc(RCEntitlementInfo) public class EntitlementInfo: NSObject {
    /**
     The entitlement identifier configured in the RevenueCat dashboard
     */
    @objc public let identifier: String

    /**
     True if the user has access to this entitlement
     */
    @objc public let isActive: Bool

    /**
     True if the underlying subscription is set to renew at the end of
     the billing period (expirationDate). Will always be True if entitlement
     is for lifetime access.
     */
    @objc public let willRenew: Bool

    /**
     The last period type this entitlement was in
     Either: RCNormal, RCIntro, RCTrial
     */
    @objc public let periodType: PeriodType

    /**
     The latest purchase or renewal date for the entitlement.
     */
    @objc public let latestPurchaseDate: Date?

    /**
     The first date this entitlement was purchased
     */
    @objc public let originalPurchaseDate: Date?

    /**
     The expiration date for the entitlement, can be `nil` for lifetime access.
     If the `periodType` is `trial`, this is the trial expiration date.
     */
    @objc public let expirationDate: Date?

    /**
     The store where this entitlement was unlocked from
     Either: RCAppStore, RCMacAppStore, RCPlayStore, RCStripe, RCPromotional, RCUnknownStore
     */
    @objc public let store: Store

    /**
     The product identifier that unlocked this entitlement
     */
    @objc public let productIdentifier: String

    /**
     False if this entitlement is unlocked via a production purchase
     */
    @objc public let isSandbox: Bool

    /**
     The date an unsubscribe was detected. Can be `nil`.

     Note: Entitlement may still be active even if user has unsubscribed. Check the `isActive` property.
     */
    @objc public let unsubscribeDetectedAt: Date?

    /**
     The date a billing issue was detected. Can be `nil` if there is no
     billing issue or an issue has been resolved.

     Note: Entitlement may still be active even if there is a billing issue.
     Check the `isActive` property.
     */
    @objc public let billingIssueDetectedAt: Date?

    /**
     Use this property to determine whether a purchase was made by the current user
     or shared to them by a family member. This can be useful for onboarding users who have had
     an entitlement shared with them, but might not be entirely aware of the benefits they now have.
     */
    @objc public let ownershipType: PurchaseOwnershipType

    @objc public convenience init(entitlementId: String,
                                  entitlementData: [String: Any],
                                  productData: [String: Any],
                                  requestDate: Date?) {
        self.init(entitlementId: entitlementId,
                  entitlementData: entitlementData,
                  productData: productData,
                  requestDate: requestDate,
                  dateFormatter: .iso8601SecondsDateFormatter)
    }

    // TODO(cleanup): Codable
    init(entitlementId: String,
         entitlementData: [String: Any],
         productData: [String: Any],
         requestDate: Date?,
         dateFormatter: DateFormatter) {
        // Entitlement data
        let entitlementExpiresDateString = entitlementData["expires_date"] as? String
        let entitlementPurchaseDateString = entitlementData["purchase_date"] as? String
        let productIdString = entitlementData["product_identifier"] as? String

        // Product data
        let periodTypeString = productData["period_type"] as? String
        let originalPurchaseDateString = productData["original_purchase_date"] as? String
        let productExpiresDateString = productData["expires_date"] as? String
        let storeString = productData["store"] as? String
        let isSandbox = (productData["is_sandbox"] as? NSNumber)?.boolValue ?? false
        let unsubscribeDetectedAtString = productData["unsubscribe_detected_at"] as? String
        let billingIssuesDetectedAtString = productData["billing_issues_detected_at"] as? String
        let ownershipType = productData["ownership_type"] as? String

        let store = Self.parseStore(store: storeString)
        let expirationDate = dateFormatter.date(fromString: productExpiresDateString)
        let unsubscribeDetectedAt = dateFormatter.date(fromString: unsubscribeDetectedAtString)
        let billingIssueDetectedAt = dateFormatter.date(fromString: billingIssuesDetectedAtString)
        let entitlementExpiresDate = dateFormatter.date(fromString: entitlementExpiresDateString)

        self.store = store
        self.expirationDate = expirationDate
        self.unsubscribeDetectedAt = unsubscribeDetectedAt
        self.billingIssueDetectedAt = billingIssueDetectedAt
        self.identifier = entitlementId
        self.productIdentifier = productIdString!
        self.isSandbox = isSandbox

        self.isActive = Self.isDateActive(expirationDate: entitlementExpiresDate, forRequestDate: requestDate)
        self.periodType = Self.parsePeriodType(periodType: periodTypeString)
        self.latestPurchaseDate = dateFormatter.date(fromString: entitlementPurchaseDateString)
        self.originalPurchaseDate = dateFormatter.date(fromString: originalPurchaseDateString)
        self.ownershipType = Self.parseOwnershipType(ownershipType: ownershipType)
        self.willRenew = Self.willRenewWithExpirationDate(expirationDate: expirationDate,
                                                          store: store,
                                                          unsubscribeDetectedAt: unsubscribeDetectedAt,
                                                          billingIssueDetectedAt: billingIssueDetectedAt)
    }

    public override var description: String {
        return """
            <\(String(describing: EntitlementInfo.self)): "
            identifier=\(self.identifier),
            isActive=\(self.isActive),
            willRenew=\(self.willRenew),
            periodType=\(self.periodType),
            latestPurchaseDate=\(String(describing: self.latestPurchaseDate)),
            originalPurchaseDate=\(String(describing: self.originalPurchaseDate)),
            expirationDate=\(String(describing: self.expirationDate)),
            store=\(self.store),
            productIdentifier=\(self.productIdentifier),
            isSandbox=\(self.isSandbox),
            unsubscribeDetectedAt=\(String(describing: self.unsubscribeDetectedAt)),
            billingIssueDetectedAt=\(String(describing: self.billingIssueDetectedAt)),
            ownershipType=\(self.ownershipType)
            >
            """
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let info = object as? EntitlementInfo else {
            return false
        }

        if self === info {
            return true
        }
        if self.identifier != info.identifier && (self.identifier != info.identifier) {
            return false
        }
        if self.isActive != info.isActive {
            return false
        }
        if self.willRenew != info.willRenew {
            return false
        }
        if self.periodType != info.periodType {
            return false
        }
        if self.latestPurchaseDate != info.latestPurchaseDate && self.latestPurchaseDate != info.latestPurchaseDate {
            return false
        }
        if self.originalPurchaseDate != info.originalPurchaseDate
            && self.originalPurchaseDate != info.originalPurchaseDate {
            return false
        }
        if self.expirationDate != info.expirationDate && self.expirationDate != info.expirationDate {
            return false
        }
        if self.store != info.store {
            return false
        }
        if self.productIdentifier != info.productIdentifier && self.productIdentifier != info.productIdentifier {
            return false
        }
        if self.isSandbox != info.isSandbox {
            return false
        }
        if self.unsubscribeDetectedAt != info.unsubscribeDetectedAt
            && self.unsubscribeDetectedAt != info.unsubscribeDetectedAt {
            return false
        }
        if self.billingIssueDetectedAt != info.billingIssueDetectedAt
            && self.billingIssueDetectedAt != info.billingIssueDetectedAt {
            return false
        }
        if self.ownershipType != info.ownershipType {
            return false
        }
        return true
    }

    public override var hash: Int {
        var hash: UInt = UInt(self.identifier.hash)
        hash = hash * UInt(31) + UInt(self.isActive.hashValue)
        hash = hash * 31 + UInt(self.willRenew.hashValue)
        hash = hash * 31 + UInt(self.periodType.hashValue)
        hash = hash * 31 + UInt(self.latestPurchaseDate?.hashValue ?? 0)
        hash = hash * 31 + UInt(self.originalPurchaseDate?.hashValue ?? 0)
        hash = hash * 31 + UInt(self.expirationDate?.hashValue ?? 0)
        hash = hash * 31 + UInt(self.store.hashValue)
        hash = hash * 31 + UInt(self.productIdentifier.hash)
        hash = hash * 31 + UInt(self.isSandbox.hashValue)
        hash = hash * 31 + UInt(self.unsubscribeDetectedAt?.hashValue ?? 0)
        hash = hash * 31 + UInt(self.billingIssueDetectedAt?.hashValue ?? 0)
        hash = hash * 31 + UInt(self.ownershipType.hashValue)
        return Int(hash)
    }

}

private extension EntitlementInfo {

    class func isDateActive(expirationDate: Date?, forRequestDate requestDate: Date?) -> Bool {
        guard let expirationDate = expirationDate else {
            return true
        }

        let referenceDate: Date = requestDate ?? Date.init()
        return expirationDate.timeIntervalSince(referenceDate) > 0
    }

    class func parseOwnershipType(ownershipType: String?) -> PurchaseOwnershipType {
        guard let ownershipType = ownershipType else {
            // TODO: should this be a warning?
            return .purchased
        }

        switch ownershipType {
        case "PURCHASED":
            return .purchased
        case "FAMILY_SHARED":
            return .familyShared
        default:
            Logger.warn("received unknown ownershipType: \(ownershipType)")
            return .unknown
        }
    }

    class func parsePeriodType(periodType: String?) -> PeriodType {
        guard let periodType = periodType else {
            Logger.warn("nil periodType found during parsePeriodType")
            return .normal
        }

        switch periodType {
        case "normal":
            return .normal
        case "intro":
            return .intro
        case "trial":
            return .trial
        default:
            Logger.warn("received unknown periodType: \(periodType)")
            return .normal
        }
    }

    class func parseStore(store: String?) -> Store {
        guard let store = store else {
            Logger.warn("nil store found during parseStore")
            return .unknownStore
        }

        switch store {
        case "app_store":
            return .appStore
        case "mac_app_store":
            return .macAppStore
        case "play_store":
            return .playStore
        case "stripe":
            return .stripe
        case "promotional":
            return .promotional
        default:
            Logger.warn("received unknown store: \(store)")
            return .unknownStore
        }
    }

    class func willRenewWithExpirationDate(expirationDate: Date?,
                                           store: Store,
                                           unsubscribeDetectedAt: Date?,
                                           billingIssueDetectedAt: Date?) -> Bool {
        let isPromo = store == .promotional
        let isLifetime = expirationDate == nil
        let hasUnsubscribed = unsubscribeDetectedAt != nil
        let hasBillingIssues = billingIssueDetectedAt != nil

        return !(isPromo || isLifetime || hasUnsubscribed || hasBillingIssues)
    }

}
