//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EntitlementInfosAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import RevenueCat_CustomEntitlementComputation

var eis: EntitlementInfos!
func checkEntitlementInfosAPI() {
    let all: [String: EntitlementInfo] = eis.all
    let active: [String: EntitlementInfo] = eis.active
    let activeInAnyEnvironment: [String: EntitlementInfo] = eis.activeInAnyEnvironment
    let activeInCurrentEnvironment: [String: EntitlementInfo] = eis.activeInCurrentEnvironment
    let enti: EntitlementInfo? = eis[""]
    // Trusted Entitlements: internal until ready to be made public.
    // let _: VerificationResult = eis.verification

    print(eis!, all, active, activeInAnyEnvironment, activeInCurrentEnvironment, enti!)
}
