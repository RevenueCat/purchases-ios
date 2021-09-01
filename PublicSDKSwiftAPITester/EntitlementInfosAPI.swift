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
import Purchases

func checkEntitlementInfosAPI() {
    let eis: Purchases.EntitlementInfos = Purchases.EntitlementInfos()
    let all: [String: Purchases.EntitlementInfo] = eis.all
    let active: [String: Purchases.EntitlementInfo] = eis.active
    let enti: Purchases.EntitlementInfo? = eis[""]

    print(eis, all, active, enti!)
}
