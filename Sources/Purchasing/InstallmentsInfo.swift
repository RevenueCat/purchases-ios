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

/// Information about the installments that a subscriber will pay across multiple billing periods
@objc(RCInstallmentsInfo) public final class InstallmentsInfo: NSObject, Sendable {

    /// Number of installments the customer commits to paying.
    @objc public let commitmentInstallmentsCount: Int

    /// Total duration of the customer's installment commitment.
    @objc public let commitmentTotalPeriod: SubscriptionPeriod

    /// Total price the customer commits to paying across all installments.
    @objc public let commitmentTotalPrice: Decimal

    /// Localized display price for ``commitmentTotalPrice``.
    @objc public let commitmentTotalDisplayPrice: String

    /// Price charged for each installment billing period.
    @objc public let installmentBillingPrice: Decimal

    /// Localized display price for ``installmentBillingPrice``.
    @objc public let installmentBillingDisplayPrice: String

    /// Creates a new ``InstallmentsInfo``.
    ///
    /// - Parameters:
    ///   - commitmentInstallmentsCount: Number of installments the customer commits to paying.
    ///   - commitmentTotalPeriod: Total duration of the customer's installment commitment.
    ///   - commitmentTotalPrice: Total price the customer commits to paying across all installments.
    ///   - commitmentTotalDisplayPrice: Localized display price for `commitmentTotalPrice`.
    ///   - installmentBillingPrice: Price charged for each installment billing period.
    ///   - installmentBillingDisplayPrice: Localized display price for `installmentBillingPrice`.
    @objc public init(
        commitmentInstallmentsCount: Int,
        commitmentTotalPeriod: SubscriptionPeriod,
        commitmentTotalPrice: Decimal,
        commitmentTotalDisplayPrice: String,
        installmentBillingPrice: Decimal,
        installmentBillingDisplayPrice: String
    ) {
        self.commitmentInstallmentsCount = commitmentInstallmentsCount
        self.commitmentTotalPeriod = commitmentTotalPeriod
        self.commitmentTotalPrice = commitmentTotalPrice
        self.commitmentTotalDisplayPrice = commitmentTotalDisplayPrice
        self.installmentBillingPrice = installmentBillingPrice
        self.installmentBillingDisplayPrice = installmentBillingDisplayPrice
    }
}
