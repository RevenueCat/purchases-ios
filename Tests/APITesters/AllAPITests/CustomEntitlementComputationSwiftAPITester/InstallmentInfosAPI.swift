//
//  InstallmentInfosAPI.swift
//  CECAPITester
//
//  Created by Will Taylor on 5/11/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import RevenueCat_CustomEntitlementComputation

func checkInstallmentsInfo(installmentsInfo: InstallmentsInfo) {
    let _: Int = installmentsInfo.installmentsCount
    let _: SubscriptionPeriod = installmentsInfo.installmentPeriod
    let _: Decimal = installmentsInfo.installmentBillingPrice
    let _: String = installmentsInfo.installmentBillingDisplayPrice
    let _: SubscriptionPeriod = installmentsInfo.commitmentTotalPeriod
    let _: Decimal = installmentsInfo.commitmentTotalPrice
    let _: String = installmentsInfo.commitmentTotalDisplayPrice
    let _: BillingPlanType = installmentsInfo.billingPlanType
}

func checkInstallmentsInfoInit() {
    let installmentsInfo: InstallmentsInfo = InstallmentsInfo(
        installmentsCount: 12,
        installmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
        installmentBillingPrice: 10,
        installmentBillingDisplayPrice: "$10.00",
        commitmentTotalPeriod: SubscriptionPeriod(value: 1, unit: .year),
        commitmentTotalPrice: 100,
        commitmentTotalDisplayPrice: "$100.00",
        billingPlanType: BillingPlanType.monthly
    )
}
