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
    let commitmentInstallmentsCount: Int = installmentsInfo.commitmentInstallmentsCount
    let commitmentInstallmentPeriod: SubscriptionPeriod = installmentsInfo.commitmentInstallmentPeriod
    let installmentBillingPrice: Decimal = installmentsInfo.installmentBillingPrice
    let installmentBillingDisplayPrice: String = installmentsInfo.installmentBillingDisplayPrice
    let commitmentTotalPeriod: SubscriptionPeriod = installmentsInfo.commitmentTotalPeriod
    let commitmentTotalPrice: Decimal = installmentsInfo.commitmentTotalPrice
    let commitmentTotalDisplayPrice: String = installmentsInfo.commitmentTotalDisplayPrice
}

func checkInstallmentsInfoInit() {
    let installmentsInfo: InstallmentsInfo = InstallmentsInfo(
        commitmentInstallmentsCount: 12,
        commitmentInstallmentPeriod: SubscriptionPeriod(value: 1, unit: .month),
        installmentBillingPrice: 10,
        installmentBillingDisplayPrice: "$10.00",
        commitmentTotalPeriod: SubscriptionPeriod(value: 1, unit: .year),
        commitmentTotalPrice: 100,
        commitmentTotalDisplayPrice: "$100.00"
    )
}
