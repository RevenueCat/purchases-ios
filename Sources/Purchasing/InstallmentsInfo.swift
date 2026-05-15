//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InstallmentsInfo.swift
//
//  Created by Will Taylor on 5/8/26.

import Foundation
import StoreKit

/// Information about the installments that a subscriber will pay across multiple billing periods
@objc(RCInstallmentsInfo) public final class InstallmentsInfo: NSObject, Sendable {

    /// Number of installments the customer commits to paying.
    @objc public let installmentsCount: Int

    /// The duration for each installment.
    @objc public let installmentPeriod: SubscriptionPeriod

    /// Price charged for each installment billing period.
    @objc public let installmentBillingPrice: Decimal

    /// Localized display price for ``installmentBillingPrice``.
    @objc public let installmentBillingDisplayPrice: String

    /// Total duration of the customer's installment commitment.
    @objc public let commitmentTotalPeriod: SubscriptionPeriod

    /// Total price the customer commits to paying across all installments.
    @objc public let commitmentTotalPrice: Decimal

    /// Localized display price for ``commitmentTotalPrice``.
    @objc public let commitmentTotalDisplayPrice: String

    /// The billing plan used for the installments.
    @objc public let billingPlanType: BillingPlanType

    /// Creates a new ``InstallmentsInfo``.
    ///
    /// - Parameters:
    ///   - installmentsCount: Number of installments the customer commits to paying.
    ///   - installmentPeriod: The duration for each installment.
    ///   - installmentBillingPrice: Price charged for each installment billing period.
    ///   - installmentBillingDisplayPrice: Localized display price for `installmentBillingPrice`.
    ///   - commitmentTotalPeriod: Total duration of the customer's installment commitment.
    ///   - commitmentTotalPrice: Total price the customer commits to paying across all installments.
    ///   - commitmentTotalDisplayPrice: Localized display price for `commitmentTotalPrice`.
    ///   - billingPlanType: Billing plan type used for the installments.
    @objc public init(
        installmentsCount: Int,
        installmentPeriod: SubscriptionPeriod,
        installmentBillingPrice: Decimal,
        installmentBillingDisplayPrice: String,
        commitmentTotalPeriod: SubscriptionPeriod,
        commitmentTotalPrice: Decimal,
        commitmentTotalDisplayPrice: String,
        billingPlanType: BillingPlanType
    ) {
        self.installmentsCount = installmentsCount
        self.installmentPeriod = installmentPeriod
        self.installmentBillingPrice = installmentBillingPrice
        self.installmentBillingDisplayPrice = installmentBillingDisplayPrice
        self.commitmentTotalPeriod = commitmentTotalPeriod
        self.commitmentTotalPrice = commitmentTotalPrice
        self.commitmentTotalDisplayPrice = commitmentTotalDisplayPrice
        self.billingPlanType = billingPlanType
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? InstallmentsInfo else { return false }

        return self.installmentsCount == other.installmentsCount
            && self.installmentPeriod == other.installmentPeriod
            && self.installmentBillingPrice == other.installmentBillingPrice
            && self.installmentBillingDisplayPrice == other.installmentBillingDisplayPrice
            && self.commitmentTotalPeriod == other.commitmentTotalPeriod
            && self.commitmentTotalPrice == other.commitmentTotalPrice
            && self.commitmentTotalDisplayPrice == other.commitmentTotalDisplayPrice
            && self.billingPlanType == other.billingPlanType
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.installmentsCount)
        hasher.combine(self.installmentPeriod)
        hasher.combine(self.installmentBillingPrice)
        hasher.combine(self.installmentBillingDisplayPrice)
        hasher.combine(self.commitmentTotalPeriod)
        hasher.combine(self.commitmentTotalPrice)
        hasher.combine(self.commitmentTotalDisplayPrice)
        hasher.combine(self.billingPlanType)

        return hasher.finalize()
    }
}
