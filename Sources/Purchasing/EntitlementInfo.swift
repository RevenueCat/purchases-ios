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

    /// For entitlements granted via the Amazon Store.
    @objc(RCAmazon) case amazon = 6

    /// For entitlements granted via RevenueCat's Web Billing
    @objc(RCBilling) case rcBilling = 7

    /// For entitlements granted via RevenueCat's External Purchases API.
    @objc(RCExternal) case external = 8

}

extension Store: CaseIterable {}
extension Store: Sendable {}

extension Store: DefaultValueProvider {

    static let defaultValue: Self = .unknownStore

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

    /// If the entitlement is under a prepaid period. This is Play Store only.
    @objc(RCPrepaid) case prepaid = 3
}

extension PeriodType: CaseIterable {}
extension PeriodType: Sendable {}

extension PeriodType: DefaultValueProvider {

    static let defaultValue: Self = .normal

}

/**
 The EntitlementInfo object gives you access to all of the information about the status of a user entitlement.
 */
@objc(RCEntitlementInfo) public final class EntitlementInfo: NSObject {

    /**
     The entitlement identifier configured in the RevenueCat dashboard
     */
    @objc public var identifier: String { self.contents.identifier }

    /**
     True if the user has access to this entitlement
     - Warning: this is equivalent to ``isActiveInAnyEnvironment``

     #### Related Symbols
     - ``isActiveInCurrentEnvironment``
     */
    @objc public var isActive: Bool { self.contents.isActive }

    /**
     True if the underlying subscription is set to renew at the end of
     the billing period (``expirationDate``).
     */
    @objc public var willRenew: Bool { self.contents.willRenew }

    /**
     The last period type this entitlement was in
     Either: ``PeriodType/normal``, ``PeriodType/intro``, ``PeriodType/trial``
     */
    @objc public var periodType: PeriodType { self.contents.periodType }

    /**
     The latest purchase or renewal date for the entitlement.
     */
    @objc public var latestPurchaseDate: Date? { self.contents.latestPurchaseDate }

    /**
     The first date this entitlement was purchased
     */
    @objc public var originalPurchaseDate: Date? { self.contents.originalPurchaseDate }

    /**
     The expiration date for the entitlement, can be `nil` for lifetime access.
     If the ``periodType`` is ``PeriodType/trial``, this is the trial expiration date.
     */
    @objc public var expirationDate: Date? { self.contents.expirationDate }

    /**
     * The store where this entitlement was unlocked from either: ``Store/appStore``, ``Store/macAppStore``,
     * ``Store/playStore``, ``Store/stripe``, ``Store/promotional``, or ``Store/unknownStore``.
     */
    @objc public var store: Store { self.contents.store }

    /**
     The product identifier that unlocked this entitlement
     */
    @objc public var productIdentifier: String { self.contents.productIdentifier }

    /**
     The product plan identifier that unlocked this entitlement (for a Google Play subscription purchase)
     */
    @objc public var productPlanIdentifier: String? { self.contents.productPlanIdentifier }

    /**
     False if this entitlement is unlocked via a production purchase
     */
    @objc public var isSandbox: Bool { self.contents.isSandbox }

    /**
     The date an unsubscribe was detected. Can be `nil`.

     - Note: Entitlement may still be active even if user has unsubscribed. Check the ``isActive`` property.
     */
    @objc public var unsubscribeDetectedAt: Date? { self.contents.unsubscribeDetectedAt }

    /**
     The date a billing issue was detected. Can be `nil` if there is no
     billing issue or an issue has been resolved.

     - Note: Entitlement may still be active even if there is a billing issue.
     Check the ``isActive`` property.
     */
    @objc public var billingIssueDetectedAt: Date? { self.contents.billingIssueDetectedAt }

    /**
     Use this property to determine whether a purchase was made by the current user
     or shared to them by a family member. This can be useful for onboarding users who have had
     an entitlement shared with them, but might not be entirely aware of the benefits they now have.
     */
    @objc public var ownershipType: PurchaseOwnershipType { self.contents.ownershipType }

    /// Whether this entitlement was verified.
    /// 
    /// ### Related Articles
    /// - [Documentation](https://rev.cat/trusted-entitlements)
    ///
    /// ### Related Symbols
    /// - ``VerificationResult``
    @objc public var verification: VerificationResult { self.contents.verification }

    // Docs inherited from protocol
    // swiftlint:disable:next missing_docs
    @objc public let rawData: [String: Any]

    // MARK: -

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
            productPlanIdentifier=\(self.productPlanIdentifier ?? "null"),
            isSandbox=\(self.isSandbox),
            unsubscribeDetectedAt=\(String(describing: self.unsubscribeDetectedAt)),
            billingIssueDetectedAt=\(String(describing: self.billingIssueDetectedAt)),
            ownershipType=\(self.ownershipType),
            verification=\(self.contents.verification)
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

        return self.contents == info.contents
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.contents)

        return hasher.finalize()
    }

    init(
        identifier: String,
        entitlement: CustomerInfoResponse.Entitlement,
        subscription: CustomerInfoResponse.Subscription,
        sandboxEnvironmentDetector: SandboxEnvironmentDetector,
        verification: VerificationResult,
        requestDate: Date
    ) {
        self.contents = .init(
            identifier: identifier,
            isActive: CustomerInfo.isDateActive(expirationDate: entitlement.expiresDate, for: requestDate),
            willRenew: Self.willRenewWithExpirationDate(expirationDate: subscription.expiresDate,
                                                        store: subscription.store,
                                                        unsubscribeDetectedAt: subscription.unsubscribeDetectedAt,
                                                        billingIssueDetectedAt: subscription.billingIssuesDetectedAt,
                                                        periodType: subscription.periodType),
            periodType: subscription.periodType,
            latestPurchaseDate: entitlement.purchaseDate,
            originalPurchaseDate: subscription.originalPurchaseDate,
            expirationDate: subscription.expiresDate,
            store: subscription.store,
            productIdentifier: entitlement.productIdentifier,
            productPlanIdentifier: subscription.productPlanIdentifier,
            isSandbox: subscription.isSandbox,
            unsubscribeDetectedAt: subscription.unsubscribeDetectedAt,
            billingIssueDetectedAt: subscription.billingIssuesDetectedAt,
            ownershipType: subscription.ownershipType,
            verification: verification
        )
        self.sandboxEnvironmentDetector = sandboxEnvironmentDetector

        self.rawData = entitlement.rawData
    }

    // MARK: -

    private let contents: Contents
    private let sandboxEnvironmentDetector: SandboxEnvironmentDetector

}

extension EntitlementInfo: RawDataContainer {}

// @unchecked because:
// - `rawData` is `[String: Any]` which can't be `Sendable`
extension EntitlementInfo: @unchecked Sendable {}

public extension EntitlementInfo {

    /// True if the user has access to this entitlement,
    /// - Note: When queried from the sandbox environment, it only returns true if active in sandbox.
    /// When queried from production, this only returns true if active in production.
    ///
    /// #### Related Symbols
    /// - ``isActiveInAnyEnvironment``
    @objc var isActiveInCurrentEnvironment: Bool {
        return (self.isActiveInAnyEnvironment &&
                self.isSandbox == self.sandboxEnvironmentDetector.isSandbox)
    }

    /// True if the user has access to this entitlement in any environment.
    ///
    /// #### Related Symbols
    /// - ``isActiveInCurrentEnvironment``
    @objc var isActiveInAnyEnvironment: Bool {
        return self.isActive
    }

}

// MARK: - Internal

extension EntitlementInfo {

    static func willRenewWithExpirationDate(expirationDate: Date?,
                                            store: Store,
                                            unsubscribeDetectedAt: Date?,
                                            billingIssueDetectedAt: Date?,
                                            periodType: PeriodType?) -> Bool {
        let isPromo = store == .promotional
        let isLifetime = expirationDate == nil
        let hasUnsubscribed = unsubscribeDetectedAt != nil
        let hasBillingIssues = billingIssueDetectedAt != nil
        // This is Play Store only for now. 
        let isPrepaid = periodType == .prepaid

        return !(isPromo || isLifetime || hasUnsubscribed || hasBillingIssues || isPrepaid)
    }

}

extension EntitlementInfo: Identifiable {

    /// The stable identity of the entity associated with this instance.
    public var id: String { return self.identifier }

}

private extension EntitlementInfo {

    struct Contents: Equatable, Hashable {

        let identifier: String
        let isActive: Bool
        let willRenew: Bool
        let periodType: PeriodType
        let latestPurchaseDate: Date?
        let originalPurchaseDate: Date?
        let expirationDate: Date?
        let store: Store
        let productIdentifier: String
        let productPlanIdentifier: String?
        let isSandbox: Bool
        let unsubscribeDetectedAt: Date?
        let billingIssueDetectedAt: Date?
        let ownershipType: PurchaseOwnershipType
        let verification: VerificationResult

    }

}

extension EntitlementInfo.Contents: Sendable {}
