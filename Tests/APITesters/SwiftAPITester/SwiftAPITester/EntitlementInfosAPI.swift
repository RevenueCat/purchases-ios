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
import RevenueCat

var eis: EntitlementInfos!
func checkEntitlementInfosAPI() {
    let all: [String: EntitlementInfo] = eis.all
    let active: [String: EntitlementInfo] = eis.active
    let activeInAnyEnvironment: [String: EntitlementInfo] = eis.activeInAnyEnvironment
    let activeInCurrentEnvironment: [String: EntitlementInfo] = eis.activeInCurrentEnvironment
    let enti: EntitlementInfo? = eis[""]

    print(eis!, all, active, activeInAnyEnvironment, activeInCurrentEnvironment, enti!)
}
