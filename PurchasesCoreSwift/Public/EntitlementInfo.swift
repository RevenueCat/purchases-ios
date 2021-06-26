//
//  EntitlementInfo.swift
//  PurchasesCoreSwift
//
//  Created by Joshua Liebowitz on 6/25/21.
//  Copyright © 2021 Purchases. All rights reserved.
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

@objcMembers @objc(RCEntitlementInfo) public class EntitlementInfo: NSObject {
    /**
     The entitlement identifier configured in the RevenueCat dashboard
     */
    public let identifier: String

    /**
     True if the user has access to this entitlement
     */
    public let isActive: Bool

    /**
     True if the underlying subscription is set to renew at the end of
     the billing period (expirationDate). Will always be True if entitlement
     is for lifetime access.
     */
    public let willRenew: Bool

    /**
     The last period type this entitlement was in
     Either: RCNormal, RCIntro, RCTrial
     */
    public let periodType: PeriodType

    /**
     The latest purchase or renewal date for the entitlement.
     */
    public let latestPurchaseDate: Date? // TODO: This used to be NON-NULL

    /**
     The first date this entitlement was purchased
     */
    public let originalPurchaseDate: Date? // TODO: This used to be NON-NULL

    /**
     The expiration date for the entitlement, can be `nil` for lifetime access.
     If the `periodType` is `trial`, this is the trial expiration date.
     */
    public private(set) var expirationDate: Date?

    /**
     The store where this entitlement was unlocked from
     Either: RCAppStore, RCMacAppStore, RCPlayStore, RCStripe, RCPromotional, RCUnknownStore
     */
    public let store: Store

    /**
     The product identifier that unlocked this entitlement
     */
    public let productIdentifier: String

    /**
     False if this entitlement is unlocked via a production purchase
     */
    public let isSandbox: Bool

    /**
     The date an unsubscribe was detected. Can be `nil`.

     Note: Entitlement may still be active even if user has unsubscribed. Check the `isActive` property.
     */
    public private(set) var unsubscribeDetectedAt: Date?

    /**
     The date a billing issue was detected. Can be `nil` if there is no
     billing issue or an issue has been resolved.

     Note: Entitlement may still be active even if there is a billing issue.
     Check the `isActive` property.
     */
    public private(set) var billingIssueDetectedAt: Date?

    /**
     Use this property to determine whether a purchase was made by the current user
     or shared to them by a family member. This can be useful for onboarding users who have had
     an entitlement shared with them, but might not be entirely aware of the benefits they now have.
     */
    public let ownershipType: PurchaseOwnershipType

    // TODO(post-migration): Make this internal
    // TODO(cleanup): Codable
    public init(entitlementId: String,
                entitlementData: [String: Any],
                productData: [String: Any],
                dateFormatter: DateFormatter,
                requestDate: Date?) {
        // Entitlement data
        let entitlementExpiresDateString = entitlementData["expires_date"] as? String
        let entitlementPurchaseDateString = entitlementData["purchase_date"] as? String
        let productIdString = entitlementData["product_identifier"] as? String

        // Product data
        let periodTypeString = productData["period_type"] as? String
        let originalPurchaseDateString = productData["original_purchase_date"] as? String
        let productExpiresDateString = productData["expires_date"] as? String
        let storeString = productData["store"] as? String
        let maybeSandbox = productData["is_sandbox"] as? NSObject // This could be a String or NSNumber
        let unsubscribeDetectedAtString = productData["unsubscribe_detected_at"] as? String
        let billingIssuesDetectedAtString = productData["billing_issues_detected_at"] as? String
        let ownershipType = productData["ownership_type"] as? String

        let store = Self.parseStore(store: storeString)
        let expirationDate = Self.parseDate(dateString: productExpiresDateString, withDateFormatter: dateFormatter)
        let unsubscribeDetectedAt = Self.parseDate(dateString: unsubscribeDetectedAtString,
                                                   withDateFormatter: dateFormatter)
        let billingIssueDetectedAt = Self.parseDate(dateString: billingIssuesDetectedAtString,
                                                    withDateFormatter: dateFormatter)
        let entitlementExpiresDate = Self.parseDate(dateString: entitlementExpiresDateString,
                                                    withDateFormatter: dateFormatter)

        self.store = store
        self.expirationDate = expirationDate
        self.unsubscribeDetectedAt = unsubscribeDetectedAt
        self.billingIssueDetectedAt = billingIssueDetectedAt
        self.identifier = entitlementId
        self.productIdentifier = productIdString!

        let isSandbox: Bool
        if maybeSandbox?.responds(to: #selector(getter: NSNumber.boolValue)) ?? false,
           let unwrapped = maybeSandbox as? NSNumber {
            isSandbox = unwrapped.boolValue
        } else if maybeSandbox?.responds(to: #selector(getter: NSString.boolValue)) ?? false,
                  let unwrapped = maybeSandbox as? NSString {
            isSandbox = unwrapped.boolValue
        } else {
            isSandbox = false
        }

        self.isSandbox = isSandbox
        self.isActive = Self.isDateActive(expirationDate: entitlementExpiresDate, forRequestDate: requestDate)
        self.periodType = Self.parsePeriodType(periodType: periodTypeString)
        self.latestPurchaseDate = Self.parseDate(dateString: entitlementPurchaseDateString,
                                                 withDateFormatter: dateFormatter)
        self.originalPurchaseDate = Self.parseDate(dateString: originalPurchaseDateString,
                                                   withDateFormatter: dateFormatter)
        self.ownershipType = Self.parseOwnershipType(ownershipType: ownershipType)
        self.willRenew = Self.willRenewWithExpirationDate(expirationDate: expirationDate,
                                                          store: store,
                                                          unsubscribeDetectedAt: unsubscribeDetectedAt,
                                                          billingIssueDetectedAt: billingIssueDetectedAt)
    }

    class func parseDate(dateString: String?, withDateFormatter dateFormatter: DateFormatter) -> Date? {
        guard let dateString = dateString else {
            return nil
        }

        return dateFormatter.date(from: dateString)
    }

    class func isDateActive(expirationDate: Date?, forRequestDate requestDate: Date?) -> Bool {
        guard let expirationDate = expirationDate else {
            return true
        }

        let referenceDate: Date = requestDate ?? Date.init()
        return expirationDate.timeIntervalSince(referenceDate) > 0
    }

    class func parseOwnershipType(ownershipType: String?) -> PurchaseOwnershipType {
        switch ownershipType {
        case nil:
            return .purchased
        case "PURCHASED":
            return .purchased
        case "FAMILY_SHARED":
            return .familyShared
        default:
            // TODO(post-migration check): Logging?
            return .unknown
        }
    }

    class func parsePeriodType(periodType: String?) -> PeriodType {
        switch periodType {
        case "normal":
            return .normal
        case "intro":
            return .intro
        case "trial":
            return .trial
        default:
            // TODO(post-migration check): Also handles nil.
            return .normal
        }
    }

    class func parseStore(store: String?) -> Store {
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
            // TODO(post-migration check): Logging?
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

    public override var description: String {
        var description = "<\(NSStringFromClass(type(of: self))): "
        description += "identifier=\(self.identifier),\n"
        description += "isActive=\(self.isActive),\n"
        description += "willRenew=\(self.willRenew),\n"
        description += "periodType=\(self.periodType),\n"
        description += "latestPurchaseDate=\(String(describing: self.latestPurchaseDate)),\n"
        description += "originalPurchaseDate=\(String(describing: self.originalPurchaseDate)),\n"
        description += "expirationDate=\(String(describing: self.expirationDate)),\n"
        description += "store=\(self.store),\n"
        description += "productIdentifier=\(self.productIdentifier),\n"
        description += "isSandbox=\(self.isSandbox),\n"
        description += "unsubscribeDetectedAt=\(String(describing: self.unsubscribeDetectedAt)),\n"
        description += "billingIssueDetectedAt=\(String(describing: self.billingIssueDetectedAt)),\n"
        description += "ownershipType=\(self.ownershipType),\n"
        description += ">"
        return description
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
