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
    @objc public var commitmentInstallmentsCount: Int { self.contents.commitmentInstallmentsCount }

    /// The duration for each installment.
    @objc public var commitmentInstallmentPeriod: SubscriptionPeriod { self.contents.commitmentInstallmentPeriod }

    /// Price charged for each installment billing period.
    @objc public var installmentBillingPrice: Decimal { self.contents.installmentBillingPrice }

    /// Localized display price for ``installmentBillingPrice``.
    @objc public var installmentBillingDisplayPrice: String { self.contents.installmentBillingDisplayPrice }

    /// Total duration of the customer's installment commitment.
    @objc public var commitmentTotalPeriod: SubscriptionPeriod { self.contents.commitmentTotalPeriod }

    /// Total price the customer commits to paying across all installments.
    @objc public var commitmentTotalPrice: Decimal { self.contents.commitmentTotalPrice }

    /// Localized display price for ``commitmentTotalPrice``.
    @objc public var commitmentTotalDisplayPrice: String { self.contents.commitmentTotalDisplayPrice }

    /// The billing plan used for the installments.
    @objc public var billingPlanType: BillingPlanType { self.contents.billingPlanType }

    /// Creates a new ``InstallmentsInfo``.
    ///
    /// - Parameters:
    ///   - commitmentInstallmentsCount: Number of installments the customer commits to paying.
    ///   - commitmentInstallmentPeriod: The duration for each installment.
    ///   - installmentBillingPrice: Price charged for each installment billing period.
    ///   - installmentBillingDisplayPrice: Localized display price for `installmentBillingPrice`.
    ///   - commitmentTotalPeriod: Total duration of the customer's installment commitment.
    ///   - commitmentTotalPrice: Total price the customer commits to paying across all installments.
    ///   - commitmentTotalDisplayPrice: Localized display price for `commitmentTotalPrice`.
    ///   - billingPlanType: Billing plan type used for the installments.
    @objc public init(
        commitmentInstallmentsCount: Int,
        commitmentInstallmentPeriod: SubscriptionPeriod,
        installmentBillingPrice: Decimal,
        installmentBillingDisplayPrice: String,
        commitmentTotalPeriod: SubscriptionPeriod,
        commitmentTotalPrice: Decimal,
        commitmentTotalDisplayPrice: String,
        billingPlanType: BillingPlanType
    ) {
        self.contents = .init(
            commitmentInstallmentsCount: commitmentInstallmentsCount,
            commitmentInstallmentPeriod: commitmentInstallmentPeriod,
            installmentBillingPrice: installmentBillingPrice,
            installmentBillingDisplayPrice: installmentBillingDisplayPrice,
            commitmentTotalPeriod: commitmentTotalPeriod,
            commitmentTotalPrice: commitmentTotalPrice,
            commitmentTotalDisplayPrice: commitmentTotalDisplayPrice,
            billingPlanType: billingPlanType
        )
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? InstallmentsInfo else { return false }

        if self === other {
            return true
        }

        return self.contents == other.contents
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.contents)

        return hasher.finalize()
    }

    private let contents: Contents
}

private extension InstallmentsInfo {

    /// Keeps equality and hashing backed by one synthesized value so new fields cannot drift out of sync.
    struct Contents: Equatable, Hashable {
        let commitmentInstallmentsCount: Int
        let commitmentInstallmentPeriod: SubscriptionPeriod
        let installmentBillingPrice: Decimal
        let installmentBillingDisplayPrice: String
        let commitmentTotalPeriod: SubscriptionPeriod
        let commitmentTotalPrice: Decimal
        let commitmentTotalDisplayPrice: String
        let billingPlanType: BillingPlanType
    }
}
