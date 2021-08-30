//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IntroEligibilityAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import Purchases

func checkIntroEligibilityAPI() {
    let introE: IntroEligibility = IntroEligibility()
    let status: IntroEligibilityStatus = introE.status

    print(introE, status)
}

func checkIntroEligibilityEnums() {
    var status = IntroEligibilityStatus.unknown
    status = .ineligible
    status = .eligible

    print(status)
}
