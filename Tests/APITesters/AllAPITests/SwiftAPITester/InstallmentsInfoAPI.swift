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
    let commitmentTotalPeriod: SubscriptionPeriod = installmentsInfo.commitmentTotalPeriod
    let commitmentTotalPrice: Decimal = installmentsInfo.commitmentTotalPrice
    let commitmentTotalDisplayPrice: String = installmentsInfo.commitmentTotalDisplayPrice
    let installmentBillingPrice: Decimal = installmentsInfo.installmentBillingPrice
    let installmentBillingDisplayPrice: String = installmentsInfo.installmentBillingDisplayPrice
}

func checkInstallmentsInfoInit() {
    let installmentsInfo: InstallmentsInfo = InstallmentsInfo(
        commitmentInstallmentsCount: 12,
        commitmentTotalPeriod: SubscriptionPeriod(value: 1, unit: .year),
        commitmentTotalPrice: 100,
        commitmentTotalDisplayPrice: "$100.00",
        installmentBillingPrice: 10,
        installmentBillingDisplayPrice: "$10.00"
    )
}
