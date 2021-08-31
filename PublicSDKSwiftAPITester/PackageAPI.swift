//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageAPI.swift
//
//  Created by Madeline Beyl on 8/26/21.

import Foundation
import Purchases

func checkPackageAPI() {
    let pack: Package = Package()
    let ident: String = pack.identifier
    let pType: PackageType = pack.packageType
    let prod: SKProduct = pack.product
    let lps: String = pack.localizedPriceString
    let lips: String = pack.localizedIntroductoryPriceString

    print(pack, ident, pType, prod, lps, lips)
}

func checkPackageEnums() {
    var type: PackageType = PackageType.unknown
    type = PackageType.custom
    type = PackageType.lifetime
    type = PackageType.annual
    type = PackageType.sixMonth
    type = PackageType.threeMonth
    type = PackageType.twoMonth
    type = PackageType.monthly
    type = PackageType.weekly

    print(type)
}
