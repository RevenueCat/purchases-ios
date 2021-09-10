//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingsAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import RevenueCat

var offs: Offerings!
func checkOfferingsAPI() {
    var off: Offering? = offs.current
    let all: [String: Offering] = offs.all
    off = offs.offering(identifier: nil)
    off = offs.offering(identifier: "")
    off = offs[""]

    print(offs!, off!, all)
}
