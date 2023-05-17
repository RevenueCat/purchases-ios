//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Matchers.swift
//
//  Created by Nacho Soto on 5/16/23.

import Foundation
import Nimble

func beCloseToNow() -> Predicate<Date> {
    return beCloseToDate(Date())
}

func beCloseToDate(_ expectedValue: Date) -> Predicate<Date> {
    return beCloseTo(expectedValue, within: 1)
}
