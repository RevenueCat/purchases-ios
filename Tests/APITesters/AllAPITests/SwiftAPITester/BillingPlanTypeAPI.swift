//
//  BillingPlanTypeAPI.swift
//
//  Created by Will Taylor on 5/13/26.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import RevenueCat

func checkBillingPlanType() {
    let _: BillingPlanType = BillingPlanType.monthly
    let _: String = BillingPlanType.monthly.rawValue

    let _: BillingPlanType = BillingPlanType.upFront
    let _: String = BillingPlanType.upFront.rawValue
}
