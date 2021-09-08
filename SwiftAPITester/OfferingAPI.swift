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
import Purchases

var off: Purchases.Offering!
func checkOfferingAPI() {
    let ident: String = off.identifier
    let sDesc: String = off.serverDescription
    let aPacks: [Purchases.Package] = off.availablePackages
    let lPack: Purchases.Package? = off.lifetime
    let annPack: Purchases.Package? = off.annual
    let smPack: Purchases.Package? = off.sixMonth
    let thmPack: Purchases.Package? = off.threeMonth
    let twmPack: Purchases.Package? = off.twoMonth
    let mPack: Purchases.Package? = off.monthly
    let wPack: Purchases.Package? = off.weekly
    var pPack: Purchases.Package? = off.package(identifier: "")
    pPack = off.package(identifier: nil)
    let package: Purchases.Package? = off[""]

    print(off!, ident, sDesc, aPacks, lPack!, annPack!, smPack!, thmPack!, twmPack!, mPack!, wPack!, pPack!, package!)
}
