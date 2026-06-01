//
//  InstallmentsInfoAPI.swift
//  SwiftAPITester
//
//  Created by Will Taylor on 5/11/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import RevenueCat

func checkInstallmentsInfo(installmentsInfo: InstallmentsInfo) {
    let _: Int = installmentsInfo.commitmentInstallmentsCount
    let _: SubscriptionPeriod = installmentsInfo.commitmentInstallmentPeriod
    let _: Decimal = installmentsInfo.installmentBillingPrice
    let _: String = installmentsInfo.installmentBillingDisplayPrice
    let _: SubscriptionPeriod = installmentsInfo.commitmentTotalPeriod
    let _: Decimal = installmentsInfo.commitmentTotalPrice
    let _: String = installmentsInfo.commitmentTotalDisplayPrice
}

func checkInstallmentsInfoInit() {
    let _: InstallmentsInfo = InstallmentsInfo(
        commitmentInstallmentsCount: 12,
        commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
        installmentBillingPrice: 10,
        installmentBillingDisplayPrice: "$10.00",
        commitmentTotalPeriod: SubscriptionPeriod(value: 1, unit: .year),
        commitmentTotalPrice: 100,
        commitmentTotalDisplayPrice: "$100.00",
        billingPlanType: BillingPlanType.monthly
    )
}
