//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferingAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import RevenueCat

var off: Offering!
func checkOfferingAPI() {
    let ident: String = off.identifier
    let sDesc: String = off.serverDescription
    let aPacks: [Package] = off.availablePackages
    let lPack: Package? = off.lifetime
    let annPack: Package? = off.annual
    let smPack: Package? = off.sixMonth
    let thmPack: Package? = off.threeMonth
    let twmPack: Package? = off.twoMonth
    let mPack: Package? = off.monthly
    let wPack: Package? = off.weekly
    var pPack: Package? = off.package(identifier: "")
    pPack = off.package(identifier: nil)
    let package: Package? = off[""]

    print(off!, ident, sDesc, aPacks, lPack!, annPack!, smPack!, thmPack!, twmPack!, mPack!, wPack!, pPack!, package!)
}
